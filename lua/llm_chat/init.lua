-- lua/llm_chat/init.lua
local M = {}

-- Load required modules
local buffer = require('llm_chat.buffer')
local client = require('llm_chat.client')

-- Default configuration
M.config = {
  -- Connection settings for LiteLLM
  litellm = {
    url = "http://localhost:4000",
    timeout = 30,
    api_key = nil,
    api_key_env = "LITELLM_API_KEY",
  },

  -- Model configuration
  models = {
    default = "anthropic-claude-3-7-sonnet", -- Hardcoded for now
  },

  -- Chat buffer appearance
  buffer = {
    filetype = "markdown",
    user_prefix = "User: ",
    assistant_prefix = "Assistant: ",
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
end

-- Create a new chat
function M.new_chat(model)
  model = model or M.config.models.default

  -- Create buffer
  local buf = buffer.create_chat_buffer()

  -- Initialize with system message
  -- TODO: Load from persona
  local system_message = {
    role = "system",
    content = "You are a helpful assistant."
  }

  local chat_data = buffer.get_chat_data(buf)
  table.insert(chat_data.messages, system_message)

  -- Setup for user input
  buffer.prompt_user(buf)

  return buf
end

-- Alias for backward compatibility
function M.open_chat(model)
  return M.new_chat(model)
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

  -- Clear input area
  buffer.clear_input(buf)

  -- Update status line
  client.update_status(buf, "Waiting for response... (0s elapsed)")

  -- Track timing for status updates
  local start_time = os.time()
  local timer = vim.loop.new_timer()

  if timer then
    -- Check every 5 seconds
    timer:start(1000, 5000, vim.schedule_wrap(function()
      local elapsed = os.time() - start_time
      local remaining = M.config.litellm.timeout - elapsed

      if remaining >= 0 then
        client.update_status(buf, string.format(
          "Waiting for response... (%ds elapsed, %ds until timeout)",
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
    end

    -- Prompt for next message
    buffer.prompt_user(buf)
  end)
end

return M
