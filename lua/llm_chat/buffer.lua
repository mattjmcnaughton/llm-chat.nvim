-- lua/llm_chat/buffer.lua
local M = {}

-- Store active chat buffers
M.active_buffers = {}

function M.setup(config)
  M.buffer_config = config.buffer or {}
  M.keymaps_config = config.keymaps or {}
end

-- Create a new chat buffer
function M.create_chat_buffer(model_name, persona_name, buf_id)
  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'filetype', M.buffer_config.filetype)

  -- Open the buffer in a new window (to the right)
  vim.api.nvim_command('rightbelow vsplit')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  -- Initialize chat
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "# llm-chat",
    "",
    "Type your message and press " .. M.keymaps_config.send .. " to send.",
    ""
  })

  -- Set up buffer-local keymaps
  if M.keymaps_config.send then
    vim.api.nvim_buf_set_keymap(buf, 'n', M.keymaps_config.send,
      [[<cmd>lua require('llm_chat').send_message()<CR>]],
      { noremap = true, silent = true, desc = 'Send message to LLM' })

    vim.api.nvim_buf_set_keymap(buf, 'i', M.keymaps_config.send,
      [[<Esc><cmd>lua require('llm_chat').send_message()<CR>]],
      { noremap = true, silent = true, desc = 'Send message to LLM' })
  end

  if M.keymaps_config.new_chat then
    vim.api.nvim_buf_set_keymap(buf, 'n', M.keymaps_config.new_chat,
      [[<cmd>lua require('llm_chat').new_chat()<CR>]],
      { noremap = true, silent = true, desc = 'Start new LLM chat' })
  end

  -- Store _initial_ buffer values, to be updated later.
  M.active_buffers[buf] = {
    messages = {},
    model = model_name,
    persona = persona_name,
    id = buf_id,
  }

  return buf
end

-- Add assistant message to buffer
function M.add_assistant_message(buf, content)
  -- Only proceed if this is one of our chat buffers
  if not M.active_buffers[buf] then
    return
  end

  -- Add message to buffer
  local lines = vim.split(content, "\n")
  local formatted_lines = {M.buffer_config.assistant_prefix}

  for _, line in ipairs(lines) do
    table.insert(formatted_lines, line)
  end

  table.insert(formatted_lines, "")
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, formatted_lines)

  -- Add to message history
  table.insert(M.active_buffers[buf].messages, {
    role = "assistant",
    content = content
  })
end

-- Get chat data for a buffer
function M.get_chat_data(buf)
  return M.active_buffers[buf]
end

-- Get current message for sending...
-- Get current message for sending and the line numbers where it's located
function M.get_current_message_with_lines()
  local buf = vim.api.nvim_get_current_buf()

  -- Get all buffer lines
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  -- Find the last user message marker
  local start_line = -1
  for i = #lines, 1, -1 do
    if string.find(lines[i], "^" .. M.buffer_config.user_prefix:gsub("%s+$", "")) then
      start_line = i
      break
    end
  end

  if start_line == -1 or start_line >= #lines then
    return "", nil, nil
  end

  -- Extract the message content (all lines after the prefix until the end or an empty line)
  local message_lines = {}
  local end_line = #lines

  for i = start_line + 1, #lines do
    if lines[i] ~= "" then
      table.insert(message_lines, lines[i])
    else
      end_line = i - 1
      break
    end
  end

  if #message_lines == 0 then
    return "", nil, nil
  end

  return table.concat(message_lines, "\n"), start_line, end_line
end

-- Format the existing user message (add a blank line after it)
function M.format_user_message(buf, start_line, end_line)
  -- Add a blank line after the message if there isn't one already
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if end_line < #lines and lines[end_line + 1] ~= "" then
    vim.api.nvim_buf_set_lines(buf, end_line + 1, end_line + 1, false, {""})
  end
end

-- Clear the input area
function M.clear_input(buf)
  -- Find where to clear
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local start_line = -1

  for i = #lines, 1, -1 do
    if lines[i] == M.buffer_config.user_prefix:gsub("%s+$", "") then
      start_line = i + 1
      break
    end
  end

  if start_line ~= -1 and start_line <= #lines then
    vim.api.nvim_buf_set_lines(buf, start_line, #lines, false, {""})
  end
end

-- Prepare for user input
function M.prompt_user(buf)
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {M.buffer_config.user_prefix, ""})

  -- Move cursor to input position
  vim.api.nvim_win_set_cursor(0, {vim.api.nvim_buf_line_count(buf), 0})
  vim.cmd("startinsert")
end

return M
