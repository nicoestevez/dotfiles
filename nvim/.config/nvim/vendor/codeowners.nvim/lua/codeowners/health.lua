local M = {}

local health = vim.health or require('health')
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

function M.check()
  start('codeowners.nvim')
  
  -- Check Neovim version
  if vim.fn.has('nvim-0.5') == 1 then
    ok('Neovim version >= 0.5')
  else
    error('Neovim version < 0.5 (required: >= 0.5)')
  end
  
  -- Check for git
  if vim.fn.executable('git') == 1 then
    ok('git executable found')
  else
    error('git executable not found')
    return
  end
  
  -- Check if we're in a git repository
  local current_dir = vim.fn.expand('%:p:h')
  local ok_git, git_root = pcall(function()
    return vim.fn.systemlist({ 'git', '-C', current_dir, 'rev-parse', '--show-toplevel' })[1]
  end)
  
  if ok_git and vim.v.shell_error == 0 and git_root and git_root ~= '' then
    ok('Inside git repository: ' .. git_root)
    
    -- Check for CODEOWNERS file
    local possible_paths = {
      git_root .. '/.github/CODEOWNERS',
      git_root .. '/CODEOWNERS',
      git_root .. '/docs/CODEOWNERS'
    }
    
    local found_codeowners = false
    for _, path in ipairs(possible_paths) do
      if vim.fn.filereadable(path) == 1 then
        ok('CODEOWNERS file found: ' .. path)
        found_codeowners = true
        
        -- Check if file is readable and has content
        local file = io.open(path, 'r')
        if file then
          local content = file:read('*line')
          file:close()
          if content and content:match('%S') then
            info('CODEOWNERS file has content')
          else
            warn('CODEOWNERS file is empty')
          end
        else
          warn('Cannot read CODEOWNERS file')
        end
        break
      end
    end
    
    if not found_codeowners then
      warn('No CODEOWNERS file found in standard locations')
      info('Expected locations:')
      for _, path in ipairs(possible_paths) do
        info('  ' .. path)
      end
    end
    
  else
    warn('Not inside a git repository')
    info('codeowners.nvim requires a git repository with CODEOWNERS file')
  end
  
  -- Test plugin functionality
  local codeowners = require('codeowners')
  local result = codeowners.codeowners()
  if type(result) == 'string' then
    if result == '' then
      info('Plugin working - no owners found for current file')
    else
      ok('Plugin working - found owners: ' .. result)
    end
  else
    error('Plugin error - codeowners() should return string')
  end
end

return M