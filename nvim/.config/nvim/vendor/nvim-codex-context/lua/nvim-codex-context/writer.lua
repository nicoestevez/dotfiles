local M = {}
local uv = vim.uv
local pid = vim.fn.getpid()

local function alive(value)
  if type(value) ~= "number" or value <= 0 or value % 1 ~= 0 then
    return false
  end
  local ok, err = uv.kill(value, 0)
  return ok ~= nil or (err and err:match("EPERM")) ~= nil
end

local function warn(message)
  vim.notify_once("[nvim-codex-context] " .. message, vim.log.levels.WARN)
end

local function read(path)
  local file = io.open(path, "r")
  if not file then
    return { instances = {} }
  end
  local content = file:read("*a")
  file:close()
  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" or type(data.instances) ~= "table" or not vim.islist(data.instances) then
    warn("Invalid context JSON; rebuilding it.")
    return { instances = {} }
  end
  return data
end

local function lock(path)
  local fd = uv.fs_open(path, "wx", 384)
  if fd then
    uv.fs_write(fd, tostring(pid))
    uv.fs_close(fd)
    return true
  end
  local file = io.open(path, "r")
  if file then
    local owner = tonumber(file:read("*a"))
    file:close()
    -- An empty lock may belong to a writer that has just created it.
    if owner and not alive(owner) then
      uv.fs_unlink(path)
    end
  end
  return false
end

function M.collect(config)
  local data = { pid = pid, timestamp = os.time() }
  if config.include.cwd then
    data.cwd = vim.fn.getcwd()
  end
  if config.include.buffers then
    data.buffers = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local file = vim.api.nvim_buf_get_name(buf)
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and file ~= "" then
        table.insert(data.buffers, file)
      end
    end
    table.sort(data.buffers)
  end
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  if config.include.active_file and vim.bo[buf].buftype == "" and file ~= "" then
    local cursor = vim.api.nvim_win_get_cursor(0)
    data.active = { file = file, line = cursor[1], col = cursor[2] + 1 }
    if config.include.treesitter then
      data.active.treesitter = require("nvim-codex-context.treesitter").get_context()
    end
  end
  return data
end

function M.update(config, instance, wait_ms)
  local path = vim.fn.expand(config.output_path)
  local dir = vim.fn.fnamemodify(path, ":h")
  local made, err = pcall(vim.fn.mkdir, dir, "p")
  if not made then
    warn("Cannot create output directory: " .. tostring(err))
    return false
  end
  local lock_path = path .. ".lock"
  local acquired = lock(lock_path)
  if not acquired and wait_ms and wait_ms > 0 then
    vim.wait(wait_ms, function()
      acquired = lock(lock_path)
      return acquired
    end, 10)
  end
  if not acquired then
    return false
  end
  local temp = path .. ".tmp." .. pid
  local ok, failure = pcall(function()
    local context = read(path)
    local instances = {}
    for _, item in ipairs(context.instances) do
      if type(item) == "table" and item.pid ~= pid and alive(item.pid) then
        table.insert(instances, item)
      end
    end
    if instance then
      table.insert(instances, instance)
    end
    if #instances == 0 then
      if uv.fs_stat(path) then
        assert(uv.fs_unlink(path))
      end
      return
    end
    local encoded = vim.json.encode({ instances = instances })
    local fd = assert(uv.fs_open(temp, "w", 384))
    local written, write_err = uv.fs_write(fd, encoded)
    uv.fs_close(fd)
    assert(written == #encoded, write_err or "Incomplete context write")
    assert(uv.fs_rename(temp, path))
  end)
  uv.fs_unlink(temp)
  uv.fs_unlink(lock_path)
  if not ok then
    warn("Cannot write context: " .. tostring(failure))
  end
  return ok
end

return M
