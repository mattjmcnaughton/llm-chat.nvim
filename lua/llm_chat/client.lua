-- lua/llm_chat/client.lua
local M = {}

local api = {}

-- Initialize client with configuration
function M.setup(config)
  api.url = config.url or "http://localhost:4000"
  api.timeout = config.timeout or 30

  -- Handle API key from env or direct config
  if config.api_key then
    api.api_key = config.api_key
  elseif config.api_key_env then
    api.api_key = os.getenv(config.api_key_env)
  end

  if not api.api_key then
    vim.notify("LLM Chat: No API key found. Set in config or environment variable.", vim.log.levels.ERROR)
  end
end

-- Send a message to LiteLLM via curl -- write JSON body to temp file
function M.chat_completion(messages, model, callback)
  local start_time = os.time()

  -- Create request body
  local body = vim.fn.json_encode({
    model = model,
    messages = messages,
  })

  -- Create a temporary file
  local temp_file = os.tmpname()

  -- Write JSON to the temporary file
  local file = io.open(temp_file, "w")
  if not file then
    callback({
      success = false,
      error = "Failed to create temporary file",
      elapsed_time = 0,
    })
    return
  end

  file:write(body)
  file:close()

  -- Build curl command with @file syntax
  local cmd = {
    "curl",
    "-s",
    "-X", "POST",
    "-H", "Content-Type: application/json",
  }

  -- Add authorization if we have an API key
  if api.api_key then
    table.insert(cmd, "-H")
    table.insert(cmd, "Authorization: Bearer " .. api.api_key)
  end

  -- Add timeout
  table.insert(cmd, "--max-time")
  table.insert(cmd, tostring(api.timeout))

  -- Add URL and data from file
  table.insert(cmd, api.url .. "/v1/chat/completions")
  table.insert(cmd, "-d")
  table.insert(cmd, "@" .. temp_file)

  -- Execute the request
  local response_text = vim.fn.system(cmd)
  local end_time = os.time()
  local elapsed = end_time - start_time

  -- Clean up the temporary file
  os.remove(temp_file)

  -- Process response
  local success, response = pcall(vim.fn.json_decode, response_text)

  if success and response.choices and response.choices[1] and response.choices[1].message then
    callback({
      success = true,
      content = response.choices[1].message.content,
      elapsed_time = elapsed,
    })
  else
    callback({
      success = false,
      error = "Failed to parse response: " .. vim.inspect(response_text):sub(1, 100),
      elapsed_time = elapsed,
    })
  end
end

-- Add a generic HTTP GET function
function M.make_get_request(endpoint, callback)
  local start_time = os.time()

  -- Build curl command
  local cmd = {
    "curl",
    "-s",
    "-X", "GET",
    "-H", "Content-Type: application/json",
  }

  -- Add authorization if we have an API key
  if api.api_key then
    table.insert(cmd, "-H")
    table.insert(cmd, "Authorization: Bearer " .. api.api_key)
  end

  -- Add timeout
  table.insert(cmd, "--max-time")
  table.insert(cmd, tostring(api.timeout))

  -- Add URL
  table.insert(cmd, api.url .. endpoint)

  -- Execute the request
  local response_text = vim.fn.system(cmd)
  local end_time = os.time()
  local elapsed = end_time - start_time

  -- Process response
  local success, response = pcall(vim.fn.json_decode, response_text)

  if success then
    callback({
      success = true,
      data = response,
      elapsed_time = elapsed,
    })
  else
    callback({
      success = false,
      error = "Failed to parse response: " .. vim.inspect(response_text):sub(1, 100),
      elapsed_time = elapsed,
    })
  end
end

-- Get available models from LiteLLM
function M.get_models(callback)
  M.make_get_request("/v1/models", function(response)
    if response.success and response.data.data then
      local models = {}
      for _, model in ipairs(response.data.data) do
        table.insert(models, model.id)
      end

      callback({
        success = true,
        models = models,
        elapsed_time = response.elapsed_time,
      })
    else
      callback({
        success = false,
        error = response.error or "Failed to fetch models",
        elapsed_time = response.elapsed_time,
      })
    end
  end)
end

-- Helper function to update chat with timing information
function M.update_status(message)
  vim.notify("llm-chat.nvim status: " .. message, vim.log.levels.INFO)
end

return M
