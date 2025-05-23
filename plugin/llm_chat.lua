if vim.fn.has('nvim-0.11.0') == 0 then
  vim.api.nvim_err_writeln('llm-chat.nvim requires Neovim 0.11.0 or higher')
  return
end

-- Helper function for command completion
local function complete_model_persona(ArgLead, CmdLine, CursorPos)
  -- Parse the command line to determine where we are
  local args = vim.split(CmdLine, '%s+', { trimempty = true })
  local cmd = args[1] -- The command itself
  table.remove(args, 1) -- Remove command, leaving only arguments

  -- Now args contains only the arguments, not the command
  -- If we have 0 args or we're typing the first arg, suggest models
  if #args == 0 or (#args == 1 and CmdLine:sub(-1) ~= ' ') then
    local models = require('llm_chat').get_cached_models()

    if ArgLead ~= '' then
      local matches = {}
      for _, name in ipairs(models) do
        if name:find('^' .. ArgLead) then
          table.insert(matches, name)
        end
      end
      return matches
    end
    return models
  -- If we have 1 complete arg and space, or we're typing the second arg, suggest personas
  elseif #args == 1 or (#args == 2 and CmdLine:sub(-1) ~= ' ') then
    local personas = require('llm_chat').get_personas()
    if ArgLead ~= '' then
      local matches = {}
      for _, name in ipairs(personas) do
        if name:find('^' .. ArgLead) then
          table.insert(matches, name)
        end
      end
      return matches
    end
    return personas
  end

  -- Default to empty list for any other case
  return {}
end

-- Helper function to parse command arguments
local function parse_args(args)
  local parts = vim.split(args, '%s+', { trimempty = true })
  local model_name = parts[1] ~= "" and parts[1] or nil
  local persona_name = parts[2] or nil
  return model_name, persona_name
end

-- Create commands
vim.api.nvim_create_user_command('LlmChat', function(opts)
  local model_name, persona_name = parse_args(opts.args)
  require('llm_chat').new_chat(model_name, persona_name)
end, {
  desc = 'Open LLM Chat buffer with optional model and persona',
  nargs = '*',
  complete = complete_model_persona
})

vim.api.nvim_create_user_command('LlmChatNew', function(opts)
  local model_name, persona_name = parse_args(opts.args)
  require('llm_chat').new_chat(model_name, persona_name)
end, {
  desc = 'Start a new LLM Chat with optional model and persona',
  nargs = '*',
  complete = complete_model_persona
})

-- Add command to list available personas
vim.api.nvim_create_user_command('LlmChatGetPersonas', function()
  local personas = require('llm_chat').get_personas()
  print("Available personas:")
  for _, name in ipairs(personas) do
    print("- " .. name)
  end
end, {
  desc = 'List available personas for LLM chat'
})

-- Add command to list available models
vim.api.nvim_create_user_command('LlmChatGetModels', function()
  require('llm_chat').get_models(function(models)
    print("Available models:")
    for _, name in ipairs(models) do
      print("- " .. name)
    end
  end)
end, {
  desc = 'List available models from LiteLLM'
})
