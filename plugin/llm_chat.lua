-- plugin/llm_chat.lua
-- Register the plugin commands

if vim.fn.has('nvim-0.11.0') == 0 then
  vim.api.nvim_err_writeln('llm-chat.nvim requires Neovim 0.11.0 or higher')
  return
end

-- Create commands
vim.api.nvim_create_user_command('LlmChat', function()
  require('llm_chat').open_chat()
end, {
  desc = 'Open LLM Chat buffer',
})
