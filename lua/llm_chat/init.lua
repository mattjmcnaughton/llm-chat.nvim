-- lua/llm_chat/init.lua
local M = {}

-- Default configuration
M.config = {
  -- We'll expand this later with all the config options
  buffer = {
    filetype = "markdown",
    user_prefix = "🧑 User: ",
    assistant_prefix = "🤖 Assistant: ",
  },
  keymaps = {
    send = "<C-s>",
    new_chat = "<C-n>",
  }
}

-- Setup function
function M.setup(opts)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Load any required modules here (we'll add them later)
end

-- Function to open a chat buffer
function M.open_chat()
  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'filetype', M.config.buffer.filetype)

  -- Open the buffer in a new window
  vim.api.nvim_command('vsplit')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  -- Add some initial text to verify it's working
  local lines = {
    "# LLM Chat",
    "",
    "Welcome to llm-chat.nvim!",
    "",
    "This is a simple test to verify the plugin is loading correctly.",
    "",
    "In the future, you'll be able to chat with an LLM here."
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

return M
