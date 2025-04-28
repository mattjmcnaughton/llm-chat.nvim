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

-- Send a request to LiteLLM using curl
function M.chat_completion(messages, model, callback)
  local start_time = os.time()

  -- Create request body
  local body = vim.fn.json_encode({
    model = model,
    messages = messages,
  })

  -- Escape the JSON for shell
  local escaped_body = vim.fn.shellescape(body)

  vim.notify("Curl request body: " .. escaped_body, vim.log.levels.INFO)
  -- Build curl command using array (to avoid shell interpretation)
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

  -- Add URL and data
  table.insert(cmd, api.url .. "/chat/completions")
  table.insert(cmd, "-d")
  table.insert(cmd, escaped_body)

  -- TODO: Use vim.loop.spawn for non-blocking requests
  -- For now, we'll use system which will block

  local response_text = vim.fn.system(cmd)
  local end_time = os.time()
  local elapsed = end_time - start_time

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

-- Helper function to update chat with timing information
function M.update_status(buf, message)
  local status_line = "Status: " .. message
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {status_line})
end

return M
