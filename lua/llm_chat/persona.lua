-- lua/llm_chat/persona.lua
local M = {}
local uv = vim.loop

-- Store loaded personas
M.personas = {}
M.persona_list = nil

function M.setup(config)
  M.config = config or {}
  M.persona_dir = M.config.directory or vim.fn.stdpath('config') .. '/llm-personas'
  M.default_persona = M.config.default or "default"
end

-- List all available personas
function M.get_all_personas()
  if M.persona_list then
    return M.persona_list
  end

  local personas = {}

  -- Ensure directory exists
  if not uv.fs_stat(M.persona_dir) then
    vim.fn.mkdir(M.persona_dir, "p")
    return personas
  end

  local handle = uv.fs_scandir(M.persona_dir)
  if not handle then
    vim.notify("Failed to scan personas directory: " .. M.persona_dir, vim.log.levels.WARN)
    return personas
  end

  while true do
    local name, type = uv.fs_scandir_next(handle)
    if not name then break end

    if type == "directory" then
      table.insert(personas, name)
    end
  end

  M.persona_list = personas
  return personas
end

-- Load a persona by name
function M.load_persona(name)
  -- Return cached persona if available
  if M.personas[name] then
    return M.personas[name]
  end

  -- Check if persona directory exists
  local persona_path = M.persona_dir .. '/' .. name
  if not uv.fs_stat(persona_path) then
    vim.notify("Persona not found: " .. name, vim.log.levels.WARN)
    return ""
  end

  -- Get all text files in the persona directory
  local files = {}
  local handle = uv.fs_scandir(persona_path)
  if not handle then
    vim.notify("Failed to scan persona directory: " .. persona_path, vim.log.levels.WARN)
    return ""
  end

  while true do
    local file_name, type = uv.fs_scandir_next(handle)
    if not file_name then break end

    if type == "file" and string.match(file_name, "%.txt$") then
      table.insert(files, file_name)
    end
  end

  -- Sort files alphabetically
  table.sort(files)

  -- Read and concatenate files
  local content = ""
  for _, file_name in ipairs(files) do
    local file_path = persona_path .. '/' .. file_name
    local fd = uv.fs_open(file_path, "r", 438)
    if fd then
      local stat = uv.fs_fstat(fd)
      if stat then
        local file_content = uv.fs_read(fd, stat.size, 0)
        content = content .. file_content .. "\n"
      end
      uv.fs_close(fd)
    end
  end

  -- Cache persona
  M.personas[name] = content
  return content
end

return M
