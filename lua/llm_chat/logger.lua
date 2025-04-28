-- lua/llm_chat/logger.lua
local M = {}
local uv = vim.loop

-- Store logger configuration
M.config = {}
M.enabled = false

function M.setup(config)
  M.config = config or {}
  M.enabled = M.config.enabled or false
  M.log_dir = M.config.directory or vim.fn.stdpath('data') .. '/llm_chat_logs'

  -- Create log directory if it doesn't exist
  if vim.fn.isdirectory(M.log_dir) == 0 then
    vim.fn.mkdir(M.log_dir, 'p')
  end
end

-- Generate a unique conversation ID
function M.generate_id()
  return string.format("%x", os.time()) .. '-' .. string.format("%x", math.random(0, 0xffff))
end

-- Get path for a chat log file
function M.get_log_path(chat_id)
  return M.log_dir .. '/' .. chat_id .. '.log'
end

-- Append a log entry to the file
function M.append_log_entry(chat_id, entry_type, data)
  if not M.enabled then
    vim.notify("Logging is disabled", vim.log.levels.DEBUG)
    return
  end

  -- Create the log entry
  local log_entry = {
    type = entry_type,
    timestamp = os.time(),
    chat_id = chat_id,
    data = data
  }

  -- Convert to JSON
  local success, json = pcall(vim.fn.json_encode, log_entry)
  if not success then
    vim.notify("Failed to encode log entry to JSON", vim.log.levels.ERROR)
    return
  end

  -- Append to the log file
  local log_path = M.get_log_path(chat_id)
  local fd = uv.fs_open(log_path, "a", 438) -- 0666 permissions, append mode
  if fd then
    uv.fs_write(fd, json .. "\n", -1) -- Add newline for JSONL format
    uv.fs_close(fd)
  else
    vim.notify("Failed to append to log file", vim.log.levels.WARN)
  end
end

-- Log a new chat creation
function M.log_new_chat(chat_data)
  if not M.enabled then
    return
  end

  local chat_metadata = {
    model = chat_data.model,
    persona = chat_data.persona,
    system_message = chat_data.messages[1] and chat_data.messages[1].content or ""
  }

  M.append_log_entry(chat_data.id, "chat_created", chat_metadata)
end

-- Log a user message
function M.log_user_message(chat_data, message)
  if not M.enabled then
    return
  end

  M.append_log_entry(chat_data.id, "user_message", {
    content = message
  })
end

-- Log an assistant message
function M.log_assistant_message(chat_data, message)
  if not M.enabled then
    return
  end

  M.append_log_entry(chat_data.id, "assistant_message", {
    content = message
  })
end

-- Log an error
function M.log_error(chat_data, error_message)
  if not M.enabled then
    return
  end

  M.append_log_entry(chat_data.id, "error", {
    message = error_message
  })
end

return M
