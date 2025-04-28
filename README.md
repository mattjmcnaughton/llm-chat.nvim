# llm-chat.nvim

A simple Neovim plugin for chatting with LLMs via LiteLLM.
Focus on simplicity and security.

## Features

- Chat with LLMs directly from Neovim
- Configure different personas for different use cases
- Automatically discover available models from LiteLLM
- Log conversations for reference
- Simple and secure implementation

Note, this plugin does _NOT_ perform auto-complete or more complex agentic
workflows.

For auto-complete, I'm interested in leveraging (huggingface/llm.nvim)[https://github.com/huggingface/llm.nvim].
Agentic workflows is still more of an open question.

## Installation

### Using lazy.nvim

```lua
{
  'mattjmcnaughton/llm-chat.nvim',
  branch = "main", -- # Or can specify a custom branch.
  config = function()
    require('llm_chat').setup({
      -- Your configuration here (optional)
    })
  end
}
```

## Configuration

Add this to your Neovim configuration:

```lua
require('llm_chat').setup({
  -- Connection settings for LiteLLM
  litellm = {
    url = "http://localhost:8000", -- URL for your LiteLLM server
    timeout = 30, -- Request timeout in seconds
    api_key = nil, -- API key (direct setting, not recommended for shared configs)
    api_key_env = "LITELLM_API_KEY", -- Environment variable for API key
  },

  -- Logging configuration
  logger = {
    enabled = true, -- Enable logging
    path = vim.fn.stdpath('data') .. '/llm_chat_logs.json', -- Log file location
  },

  -- Persona configuration
  personas = {
    directory = vim.fn.stdpath('config') .. '/llm-personas', -- Directory for personas
    default = "general", -- Default persona to use
  },

  -- Model configuration
  models = {
    default = "gpt-4", -- Fallback model if discovery fails
    cache_ttl = 3600, -- How long to cache model list (in seconds)
  },

  -- Chat buffer appearance
  buffer = {
    filetype = "markdown", -- Use markdown for syntax highlighting
    user_prefix = "🧑 User: ", -- Prefix for user messages
    assistant_prefix = "🤖 Assistant: ", -- Prefix for assistant responses
  },

  -- Keymaps for chat buffer (nil means no mapping)
  keymaps = {
    send = "<C-s>", -- Ctrl+s to send message
    new_chat = "<C-n>", -- Ctrl+n to start new chat
  }
})

-- Optional: Add custom commands or keymaps
vim.api.nvim_set_keymap('n', '<leader>lc', ':LlmChat<CR>', { noremap = true, desc = 'Open LLM Chat' })
```

### API Key Configuration

The plugin requires an API key to authenticate with LiteLLM. You have two options to provide this:

1. **Environment Variable (Recommended)**:
   Set the `LITELLM_API_KEY` environment variable before starting Neovim:
   ```bash
   export LITELLM_API_KEY="your-api-key-here"
   ```

2. **Direct Configuration**:
   Set the API key directly in your config (not recommended for shared configurations):
   ```lua
   require('llm_chat').setup({
     litellm = {
       api_key = "your-api-key-here",
       -- Other settings...
     },
     -- Other settings...
   })
   ```

You can also change the name of the environment variable by setting `api_key_env`:
```lua
require('llm_chat').setup({
  litellm = {
    api_key_env = "MY_CUSTOM_API_KEY_ENV",
    -- Other settings...
  },
  -- Other settings...
})
```

## Setting Up Personas

Create a directory structure for your personas:

```
~/.config/nvim/llm-personas/
├── general/
│   └── 01-helpful-assistant.txt
├── python-expert/
│   ├── 01-python-knowledge.txt
│   └── 02-coding-style.txt
└── creative-writer/
    └── 01-storytelling.txt
```

Each persona is a directory containing text files. The files will be concatenated in alphabetical order to form the system instructions for the LLM.

Example content for `~/.config/nvim/llm-personas/python-expert/01-python-knowledge.txt`:

```
You are a Python programming expert. You have extensive knowledge of Python's standard library,
popular frameworks, and best practices. When responding to code questions:
- Provide efficient, Pythonic solutions
- Explain key concepts and design decisions
- Include code examples when appropriate
- Follow PEP 8 style guidelines
```

## Usage

### Commands

- `:LlmChat` - Start a chat with the default model and persona (alias for `:LlmChatNew`)
- `:LlmChatNew` - Start a new chat with specified model and persona
- `:LlmChatNew gpt-4` - Start a chat with a specific model
- `:LlmChatNew gpt-4 python-expert` - Start a chat with specific model and persona
- `:LlmChatGetPersonas` - List available personas
- `:LlmChatGetModels` - List available models via LiteLLM

### In Chat Buffer

- Type your message
- Press `Ctrl+s` to send (or the key you configured)
- Press `Ctrl+n` to start a new chat (or the key you configured)

## Requirements

- Neovim 0.11.0+
- LiteLLM server running locally or remotely
- API key for LiteLLM

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
