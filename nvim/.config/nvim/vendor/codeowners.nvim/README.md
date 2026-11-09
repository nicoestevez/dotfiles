# codeowners.nvim

A Neovim plugin that integrates with Git's CODEOWNERS file to display code ownership information in your editor.

## Features

- 🔍 Automatically finds CODEOWNERS files in standard locations
- ⚡ Cached parsing for performance
- 📊 Lualine integration ready
- 🎯 Glob pattern matching support
- 👥 Clean owner display formatting

## Requirements

- Neovim >= 0.5.0
- Git repository with CODEOWNERS file

## Installation

### lazy.nvim

```lua
{
  'JonasGavenavicius/codeowners.nvim',
  config = function()
    require('codeowners').setup()
  end
}
```

### packer.nvim

```lua
use {
  'JonasGavenavicius/codeowners.nvim',
  config = function()
    require('codeowners').setup()
  end
}
```

### vim-plug

```vim
Plug 'JonasGavenavicius/codeowners.nvim'
```

Then run `:PlugInstall` and add to your init.lua:

```lua
require('codeowners').setup()
```

## Usage

### Lualine Integration

Add to your lualine configuration:

```lua
require('lualine').setup {
  sections = {
    lualine_c = {
      'filename',
      require('codeowners').codeowners
    }
  }
}
```

### Manual Usage

```lua
local codeowners = require('codeowners')
local owners = codeowners.codeowners()
print(owners) -- "👥 username" or "👥 user1,user2" or ""
```

## How It Works

The plugin:

1. Finds CODEOWNERS files in these locations (in order):
   - `CODEOWNERS` (repository root)
   - `.github/CODEOWNERS`
   - `docs/CODEOWNERS`

2. Parses the file and caches the rules

3. Matches the current file against CODEOWNERS patterns

4. Returns formatted owner information:
   - Single owner: `👥 username`
   - Multiple owners (≤3): `👥 user1,user2,user3`
   - Many owners (>3): `👥 user1 +2`
   - No owners: `""` (empty string)

## CODEOWNERS File Support

The plugin supports standard CODEOWNERS syntax:

```
# Global owners
* @global-owner1 @global-owner2

# JavaScript files
*.js @js-team

# Documentation
docs/ @docs-team @technical-writers

# Specific directories
/src/auth/ @security-team

# Multiple patterns
*.{ts,tsx} @frontend-team
```

## Performance

- CODEOWNERS files are parsed once and cached
- Cache is automatically invalidated when the file changes
- Glob pattern matching is optimized for common patterns

## Configuration

The plugin works out of the box but can be customized:

```lua
require('git-owners').setup({
  icon = '👥',          -- Icon to show (default: '👥')
  show_icon = true,     -- Show icon (default: true)
  max_owners = 3,       -- Max owners before truncating (default: 3)
  separator = ',',      -- Separator between owners (default: ',')
})
```

### Examples

```lua
-- Minimal setup
require('codeowners').setup()

-- Custom icon and separator
require('git-owners').setup({
  icon = '🔒',
  separator = ' | ',
  max_owners = 5
})

-- No icon, just text
require('git-owners').setup({
  show_icon = false
})
```

## Health Check

Run `:checkhealth codeowners` to verify your setup:

- Checks Neovim version compatibility
- Verifies git is available
- Confirms you're in a git repository  
- Locates CODEOWNERS files
- Tests plugin functionality

## Testing

Run tests with your preferred Neovim test runner:

```bash
nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
```

## License

MIT