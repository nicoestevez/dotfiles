local M = {}

-- Plugin configuration
local config = {
  icon = '👥',
  show_icon = true,
  max_owners = 3,
  separator = ',',
}

-- Cache for parsed CODEOWNERS data
local codeowners_cache = {}
local cache_timestamp = ''
local display_cache = {}

-- Find CODEOWNERS file in project
local function find_codeowners_file()
  local current_dir = vim.fn.expand('%:p:h')
  
  -- Check if we're in a git repository
  local ok, git_root = pcall(function()
    return vim.fn.systemlist({ 'git', '-C', current_dir, 'rev-parse', '--show-toplevel' })[1]
  end)
  
  if not ok or vim.v.shell_error ~= 0 or not git_root or git_root == '' then
    return nil
  end
  
  local possible_paths = {
    git_root .. '/.github/CODEOWNERS',
    git_root .. '/CODEOWNERS',
    git_root .. '/docs/CODEOWNERS'
  }
  
  for _, path in ipairs(possible_paths) do
    if vim.fn.filereadable(path) == 1 then
      return path, git_root
    end
  end
  
  return nil
end

-- Parse CODEOWNERS file
local function parse_codeowners(filepath)
  local file = io.open(filepath, 'r')
  if not file then
    return {}
  end
  
  local rules = {}
  for line in file:lines() do
    line = line:match('^%s*(.-)%s*$') -- trim whitespace
    
    -- Skip empty lines and comments
    if line ~= '' and not line:match('^#') then
      local parts = vim.split(line, '%s+')
      if #parts >= 1 then
        local pattern = parts[1]
        local owners = {}
        for i = 2, #parts do
          if parts[i]:sub(1, 1) == '#' then break end
          table.insert(owners, parts[i])
        end
        table.insert(rules, {pattern = pattern, owners = owners})
      end
    end
  end
  
  file:close()
  return rules
end

-- Match path segments so **/ also includes zero directories.
local function matches_pattern(filepath, glob)
  local anchored = glob:sub(1, 1) == '/' or glob:gsub('/$', ''):find('/', 1, true) ~= nil
  local directory = glob:sub(-1) == '/'
  glob = glob:gsub('^/', ''):gsub('/$', '')
  local patterns = vim.split(glob, '/', { plain = true })
  local segments = vim.split(filepath, '/', { plain = true })

  local function match(pattern_index, path_index)
    if pattern_index > #patterns then
      return not directory or path_index <= #segments
    end
    local pattern = patterns[pattern_index]
    if pattern == '**' then
      if match(pattern_index + 1, path_index) then return true end
      return path_index <= #segments and match(pattern_index, path_index + 1)
    end
    if path_index > #segments then return false end
    pattern = pattern:gsub('([%%%^%$%(%)%.%[%]%+%-])', '%%%1')
      :gsub('%*', '.*'):gsub('%?', '.')
    return segments[path_index]:match('^' .. pattern .. '$') ~= nil
      and match(pattern_index + 1, path_index + 1)
  end

  if anchored then return match(1, 1) end
  for index = 1, #segments do
    if match(1, index) then return true end
  end
  return false
end

-- Get owners for current file
local function get_file_owners()
  local current_dir = vim.fn.expand('%:p:h')
  local current_file = (vim.loop.fs_realpath(current_dir) or current_dir) .. '/' .. vim.fn.expand('%:t')
  local codeowners_file, git_root = find_codeowners_file()
  
  if not codeowners_file then
    return {}
  end
  
  local file_stat = vim.loop.fs_stat(codeowners_file)
  if not file_stat then
    return {}
  end
  
  local timestamp = tostring(file_stat.mtime.sec) .. ':' .. tostring(file_stat.mtime.nsec)
  -- Check cache validity
  if codeowners_cache.filepath ~= codeowners_file or 
     cache_timestamp ~= timestamp then
    codeowners_cache = {
      filepath = codeowners_file,
      rules = parse_codeowners(codeowners_file)
    }
    cache_timestamp = timestamp
  end
  
  local relative_path = current_file:sub(#git_root + 2) -- +2 to remove leading slash
  
  -- Find matching owners (last match wins)
  local owners = {}
  for _, rule in ipairs(codeowners_cache.rules) do
    if matches_pattern(relative_path, rule.pattern) then
      owners = rule.owners
    end
  end
  
  return owners
end

-- Format owners for display
local function format_owners(owners)
  if #owners == 0 then
    return ''
  end
  
  -- Remove @ prefix for cleaner display
  local clean_owners = {}
  for _, owner in ipairs(owners) do
    if type(owner) == 'string' then
      clean_owners[#clean_owners + 1] = owner:gsub('^@', '')
    end
  end
  
  local formatted = ''
  if #clean_owners == 1 then
    formatted = clean_owners[1]
  elseif #clean_owners <= config.max_owners then
    formatted = table.concat(clean_owners, config.separator)
  else
    formatted = clean_owners[1] .. ' +' .. (#clean_owners - 1)
  end
  
  if config.show_icon then
    return config.icon .. ' ' .. formatted
  end
  
  return formatted
end

-- Main function for lualine
function M.codeowners()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].buftype ~= '' or vim.api.nvim_buf_get_name(bufnr) == '' then return '' end
  if display_cache[bufnr] ~= nil then return display_cache[bufnr] end
  local ok, result = pcall(function()
    local owners = get_file_owners()
    return format_owners(owners)
  end)
  
  if not ok then
    return ''
  end
  
  display_cache[bufnr] = result
  return result
end

-- Setup function
function M.setup(opts)
  opts = opts or {}
  
  -- Merge user config with defaults
  config = vim.tbl_deep_extend('force', config, opts)
  display_cache = {}
  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'BufFilePost', 'BufDelete', 'DirChanged', 'FocusGained' }, {
    group = vim.api.nvim_create_augroup('CodeownersDisplay', { clear = true }),
    callback = function() display_cache = {} end,
  })
end

-- Get current configuration
function M.get_config()
  return vim.deepcopy(config)
end

return M
