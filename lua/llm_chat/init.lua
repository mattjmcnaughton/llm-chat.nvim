-- lua/llm_chat/init.lua
local M = {}

-- Load required modules
local buffer = require('llm_chat.buffer')
local client = require('llm_chat.client')
local persona = require('llm_chat.persona')
local model = require('llm_chat.model')
local logger = require('llm_chat.logger')

-- Default configuration
M.config = {
  -- Connection settings for LiteLLM
  litellm = {
    url = "http://localhost:4000",
    timeout = 30,
    api_key = nil,
    api_key_env = "LITELLM_API_KEY",
  },

  -- Add persona configuration
  personas = {
    directory = vim.fn.stdpath('config') .. '/llm-personas',
    default = "default",
  },

  -- Model configuration
  models = {
    default = "anthropic-claude-3-7-sonnet", -- Default model
    cache_ttl = 3600,

  },

  -- Chat buffer appearance
  buffer = {
    filetype = "markdown",
    user_prefix = "User: ",
    assistant_prefix = "Assistant: ",
  },

  logger = {
    enabled = true,
    directory = vim.fn.stdpath('data') .. '/llm_chat_logs',
  },

  -- Keymaps for chat buffer
  keymaps = {
    send = "<C-s>",
    new_chat = "<C-n>",
  }
}

-- Setup function
function M.setup(opts)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Initialize components
  client.setup(M.config.litellm)
  buffer.setup({
    buffer = M.config.buffer,
    keymaps = M.config.keymaps
  })
  persona.setup(M.config.personas)
  model.setup(M.config.models)

    -- Fetch models on startup
  vim.defer_fn(function()
    model.fetch_models(function(models, error)
      if error then
        vim.notify("Failed to fetch initial models: " .. error, vim.log.levels.WARN)
      else
        vim.notify("Fetched " .. #models .. " models from LiteLLM", vim.log.levels.INFO)
      end
    end)
  end, 100) -- Short delay to ensure everything is initialized
end

-- Create a new chat
function M.new_chat(model_name, persona_name)
  model_name = model_name or M.config.models.default
  persona_name = persona_name or nil

  -- Create buffer
  local buf = buffer.create_chat_buffer()

  -- Initialize with system message
  local system_content = ""
  if persona_name then
    system_content = persona.load_persona(persona_name)
  end
  local system_message = {
    role = "system",
    content = system_content
  }

  local chat_data = buffer.get_chat_data(buf)
  chat_data.model = model_name
  chat_data.persona = persona_name
  table.insert(chat_data.messages, system_message)

  logger.log_new_chat(chat_data)

  -- Update buffer title to show persona
  local title = "# llm-chat"
    if model_name then
    title = title .. " (Model: " .. model_name .. ")"
  end
  if persona_name then
    title = title .. " (Persona: " .. persona_name .. ")"
  end
  vim.api.nvim_buf_set_lines(buf, 0, 1, false, {title})

  -- Setup for user input
  buffer.prompt_user(buf)

  return buf
end

-- Alias for backward compatibility
function M.open_chat(model)
  return M.new_chat(model)
end

function M.get_personas()
  return persona.get_all_personas()
end

-- Send the current message
function M.send_message()
  local buf = vim.api.nvim_get_current_buf()
  local chat_data = buffer.get_chat_data(buf)

  if not chat_data then
    vim.notify("Not in an LLM chat buffer", vim.log.levels.ERROR)
    return
  end

  -- Get the current message
  local message = buffer.get_current_message()

  if message == "" then
    vim.notify("No message to send", vim.log.levels.WARN)
    return
  end

  -- Add to buffer display
  buffer.add_user_message(buf, message)
  logger.log_user_message(chat_data, message)

  -- Clear input area
  buffer.clear_input(buf)

  -- Update status line
  client.update_status(buf, "Waiting for response... (0s elapsed)")

  -- Track timing for status updates
  local start_time = os.time()
  local timer = vim.loop.new_timer()

  if timer then
    -- Start checking after 10 seconds, then update every 5 seconds
    timer:start(10000, 5000, vim.schedule_wrap(function()
      local elapsed = os.time() - start_time
      local remaining = M.config.litellm.timeout - elapsed

      if remaining >= 0 then
        client.update_status(buf, string.format(
          "Waiting... (%ds elapsed, %ds until timeout)",
          elapsed, remaining
        ))
      end
    end))
  end

  -- Send request to LiteLLM
  client.chat_completion(chat_data.messages, chat_data.model, function(response)
    -- Stop the timer
    if timer then
      timer:stop()
      timer:close()
    end

    -- Process response
    if response.success then
      -- Add assistant response to buffer
      buffer.add_assistant_message(buf, response.content)
      logger.log_assistant_message(chat_data, response.content)

      -- Add timing information
      client.update_status(buf, string.format(
        "Response received in %d seconds",
        response.elapsed_time
      ))
    else
      -- Handle error
      client.update_status(buf, string.format(
        "Error: %s (after %d seconds)",
        response.error, response.elapsed_time
      ))
      logger.log_error(chat_data, response.error)
    end

    -- Prompt for next message
    buffer.prompt_user(buf)
  end)
end

function M.get_models(callback)
  model.fetch_models(function(models, error)
    if error then
      vim.notify("Failed to fetch models: " .. error, vim.log.levels.WARN)
    end
    if callback then
      callback(models)
    end
  end)
end

-- Expose models cache for tab completion
function M.get_cached_models()
  return model.models or {}
end

return M
