-- lua/llm_chat/client.lua
local M = {}

local api = {}
local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("cjson")

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

-- Send a request to LiteLLM
function M.chat_completion(messages, model, callback)
  local start_time = os.time()
  local timeout_time = start_time + api.timeout

  -- Create request body
  local body = json.encode({
    model = model,
    messages = messages,
  })

  -- Set up headers
  local headers = {
    ["Content-Type"] = "application/json",
    ["Content-Length"] = #body,
  }

  if api.api_key then
    headers["Authorization"] = "Bearer " .. api.api_key
  end

  -- Create response table
  local response_body = {}

  -- TODO: Implement proper async HTTP request
  -- Currently using synchronous request which will block Neovim

  -- Set up request
  local _, code = http.request {
    url = api.url .. "/chat/completions",
    method = "POST",
    headers = headers,
    source = ltn12.source.string(body),
    sink = ltn12.sink.table(response_body),
    timeout = api.timeout,
  }

  local end_time = os.time()
  local elapsed = end_time - start_time

  -- Process response
  if code == 200 then
    local response_text = table.concat(response_body)
    local response = json.decode(response_text)

    callback({
      success = true,
      content = response.choices[1].message.content,
      elapsed_time = elapsed,
    })
  else
    callback({
      success = false,
      error = "Request failed with code: " .. (code or "unknown"),
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
