local M = {}
local writer = require("nvim-codex-context.writer")
local config
local timer
local generation = 0
local stopping = false
local defaults = {
  output_path = "~/.codex/nvim-context.json",
  debounce_ms = 100,
  mode = "auto",
  enabled = true,
  include = { cwd = true, active_file = true, buffers = true, treesitter = true },
}

local function cancel()
  generation = generation + 1
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

local function copy()
  vim.fn.setreg("+", vim.json.encode(writer.collect(config)))
  vim.notify("[nvim-codex-context] Context copied to clipboard")
end

local function publish(wait_ms)
  if stopping or not config or not config.enabled or config.mode ~= "auto" then
    return true
  end
  return writer.update(config, writer.collect(config), wait_ms)
end

local function schedule()
  cancel()
  if stopping or not config.enabled or config.mode ~= "auto" then
    return
  end
  local current = generation
  timer = vim.uv.new_timer()
  timer:start(config.debounce_ms, 0, vim.schedule_wrap(function()
    if current ~= generation then
      return
    end
    cancel()
    if not publish() then
      schedule()
    end
  end))
end

function M.refresh()
  if not config or not config.enabled then
    return
  end
  cancel()
  if config.mode == "manual" then
    copy()
  elseif not publish(100) then
    schedule()
  end
end

function M.disable()
  if not config then
    return
  end
  config.enabled = false
  cancel()
  if config.mode == "auto" then
    writer.update(config, nil, 200)
  end
end

function M.enable()
  if config then
    config.enabled = true
    M.refresh()
  end
end

function M.copy()
  if config then
    copy()
  end
end

function M.setup(opts)
  if config then
    M.disable()
  end
  config = vim.tbl_deep_extend("force", {}, defaults, opts or {})
  assert(config.mode == "auto" or config.mode == "manual", "mode must be auto or manual")
  assert(type(config.debounce_ms) == "number" and config.debounce_ms >= 0, "debounce_ms must be nonnegative")
  assert(type(config.output_path) == "string" and config.output_path ~= "", "output_path must be nonempty")
  stopping = false
  local group = vim.api.nvim_create_augroup("NvimCodexContext", { clear = true })
  vim.api.nvim_create_autocmd({
    "BufEnter", "BufDelete", "BufWipeout", "BufFilePost", "BufWritePost",
    "CursorMoved", "CursorMovedI", "DirChanged", "FocusGained",
  }, { group = group, callback = schedule })
  vim.api.nvim_create_autocmd("FocusLost", {
    group = group,
    callback = function()
      cancel()
      if not publish(100) then
        schedule()
      end
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      stopping = true
      cancel()
      if config.mode == "auto" then
        writer.update(config, nil, 200)
      end
    end,
  })
  local commands = {
    Refresh = M.refresh, Enable = M.enable, Disable = M.disable, Copy = M.copy,
  }
  for suffix, callback in pairs(commands) do
    vim.api.nvim_create_user_command("CodexContext" .. suffix, callback, {
      desc = suffix .. " Codex editor context", force = true,
    })
  end
  if not publish() then
    schedule()
  end
end

return M
