-- lua/llm_chat/model.lua (simplified)
local M = {}
local client = require('llm_chat.client')

-- Store discovered models
M.models = {}
M.last_fetch_time = 0

function M.setup(config)
  M.config = config or {}
  M.cache_ttl = M.config.cache_ttl or 3600 -- Default 1 hour cache
  M.default_model = M.config.default or "anthropic-claude-3-7-sonnet"
end

-- Fetch available models from LiteLLM
function M.fetch_models(callback)
  local current_time = os.time()

  -- Return cached models if they exist and are still valid
  if M.models and #M.models > 0 and (current_time - M.last_fetch_time) < M.cache_ttl then
    if callback then
      callback(M.models, nil)
    end
    return M.models
  end

  -- Fetch new models
  client.get_models(function(response)
    if response.success then
      -- Cache the result
      M.models = response.models
      M.last_fetch_time = current_time

      if callback then
        callback(M.models, nil)
      end
    else
      -- Fall back to default
      local fallback = {M.default_model}

      if callback then
        callback(fallback, response.error)
      end
    end
  end)
end

-- Get all available models
function M.get_all_models(callback)
  return M.fetch_models(callback)
end

return M
