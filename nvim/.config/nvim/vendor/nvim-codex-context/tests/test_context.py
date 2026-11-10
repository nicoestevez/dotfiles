"""Integration tests using real Neovim processes and isolated output paths."""

import json
from pathlib import Path
import subprocess
import tempfile
import time
import unittest


PLUGIN = Path(__file__).resolve().parents[1]


class ContextTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name).resolve()
        self.processes = []
        self.counter = 0

    def tearDown(self):
        for process in self.processes:
            if process.poll() is None:
                process.terminate()
            try:
                process.communicate(timeout=3)
            except subprocess.TimeoutExpired:
                process.kill()
                process.communicate()
        self.temp.cleanup()

    def start(self, body):
        self.counter += 1
        script = self.root / f"test-{self.counter}.lua"
        script.write_text(
            f"vim.opt.rtp:prepend({json.dumps(str(PLUGIN))})\n"
            f"local root = {json.dumps(str(self.root))}\n"
            f"local config_root = {json.dumps(str(PLUGIN.parents[1]))}\n"
            'local output = root .. "/context.json"\n'
            'local plugin = require("nvim-codex-context")\n'
            'local function read() return vim.json.decode(table.concat(vim.fn.readfile(output), "\\n")) end\n'
            + body
        )
        process = subprocess.Popen(
            ["nvim", "--headless", "-u", "NONE", "-i", "NONE", "-l", str(script)],
            cwd=self.root, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        )
        self.processes.append(process)
        return process

    def run_lua(self, body):
        process = self.start(body)
        stdout, stderr = process.communicate(timeout=15)
        self.assertEqual(process.returncode, 0, stdout + stderr)
        return stdout + stderr

    def wait_for(self, predicate):
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            try:
                if predicate():
                    return
            except (FileNotFoundError, json.JSONDecodeError):
                pass
            time.sleep(0.02)
        self.fail("Timed out waiting for context update")

    def context(self):
        return json.loads((self.root / "context.json").read_text())["instances"]

    def test_metadata_events_and_disable(self):
        self.run_lua(r'''
vim.cmd.edit(root .. "/sample.lua")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local function hello()", "  return 42", "end" })
vim.api.nvim_win_set_cursor(0, { 2, 3 })
plugin.setup({ output_path = output, debounce_ms = 20, include = { treesitter = false } })
local data = read().instances[1]
assert(data.cwd == root and data.pid == vim.fn.getpid())
assert(data.active.line == 2 and data.active.col == 4)
assert(data.active.file == root .. "/sample.lua" and #data.buffers == 1)
assert(data.active.treesitter == nil and data.timestamp > 0)
vim.api.nvim_win_set_cursor(0, { 3, 0 })
vim.api.nvim_exec_autocmds("CursorMoved", {})
assert(read().instances[1].active.line == 2, "debounce must delay publication")
assert(vim.wait(1000, function() return read().instances[1].active.line == 3 end, 10))
vim.cmd.enew()
vim.bo.buftype = "nofile"
vim.cmd.CodexContextRefresh()
assert(read().instances[1].active == nil)
assert(#read().instances[1].buffers == 1)
vim.cmd.enew()
local terminal = vim.fn.jobstart({ "cat" }, { term = true })
vim.cmd.CodexContextRefresh()
assert(read().instances[1].active == nil)
vim.fn.jobstop(terminal)
vim.cmd("enew!")
vim.cmd.edit(root .. "/other.lua")
vim.api.nvim_exec_autocmds("CursorMoved", {})
vim.cmd.CodexContextDisable()
assert(not vim.uv.fs_stat(output))
vim.wait(60, function() return false end, 10)
assert(not vim.uv.fs_stat(output), "pending callback republished disabled context")
vim.cmd.CodexContextEnable()
assert(read().instances[1].active.file == root .. "/other.lua")
vim.cmd.bdelete()
assert(vim.wait(1000, function() return #read().instances[1].buffers == 1 end, 10))
vim.fn.mkdir(root .. "/sub", "p")
vim.cmd.cd(root .. "/sub")
vim.api.nvim_exec_autocmds("FocusLost", {})
assert(read().instances[1].cwd == root .. "/sub")
plugin.setup({ output_path = output, include = { treesitter = false } })
assert(#read().instances == 1, "setup must be idempotent")
''')
        self.assertFalse((self.root / "context.json").exists())

    def test_manual_clipboard_and_missing_parser(self):
        self.run_lua(r'''
local copied
vim.g.clipboard = {
  name = "test", copy = { ["+"] = function(lines) copied = table.concat(lines, "\n") end,
  ["*"] = function() end }, paste = { ["+"] = function() return {} end, ["*"] = function() return {} end },
}
vim.cmd.edit(root .. "/sample.unknown")
vim.bo.filetype = "missing_parser_for_test"
plugin.setup({ output_path = output, mode = "manual" })
assert(not vim.uv.fs_stat(output) and not copied)
vim.cmd.CodexContextRefresh()
assert(vim.json.decode(copied).active.file == root .. "/sample.unknown")
assert(vim.json.decode(copied).active.treesitter == nil)
vim.cmd.CodexContextCopy()
assert(not vim.uv.fs_stat(output))
plugin.setup({ output_path = output })
assert(read().instances[1].active.treesitter == nil)
vim.cmd.CodexContextCopy()
assert(vim.json.decode(copied).pid == vim.fn.getpid())
''')

    def test_lua_treesitter(self):
        result = self.run_lua(r'''
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/site")
if not vim.treesitter.language.add("lua") then print("SKIP_PARSER"); return end
vim.cmd.edit(root .. "/sample.lua")
vim.bo.filetype = "lua"
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local function hello()", "  return 42", "end" })
vim.api.nvim_win_set_cursor(0, { 2, 2 })
plugin.setup({ output_path = output })
assert(read().instances[1].active.treesitter["function"] == "hello")
''')
        if "SKIP_PARSER" in result:
            self.skipTest("Lua parser is not installed")

    def test_recovery_and_unwritable_output(self):
        self.run_lua(r'''
vim.fn.writefile({ "broken json" }, output)
vim.fn.writefile({ "2147483647" }, output .. ".lock")
plugin.setup({ output_path = output, debounce_ms = 10 })
assert(vim.wait(1000, function()
  local ok, data = pcall(read)
  return ok and #data.instances == 1
end, 10))
vim.fn.writefile({ vim.json.encode({ instances = { { pid = 2147483647 } } }) }, output)
plugin.refresh()
assert(#read().instances == 1 and read().instances[1].pid == vim.fn.getpid())
plugin.disable()
vim.fn.writefile({ "not a directory" }, root .. "/blocked")
plugin.setup({ output_path = root .. "/blocked/context.json", debounce_ms = 10 })
vim.wait(30, function() return false end, 10)
plugin.disable()
assert(not vim.uv.fs_stat(output .. ".lock"))
''')

    def test_lazy_registration(self):
        self.run_lua(r'''
vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/lazy.nvim")
-- Resolve stdpath("config") in the real spec to this checkout for isolation.
local stdpath = vim.fn.stdpath
vim.fn.stdpath = function(kind)
  if kind == "config" then return config_root end
  return stdpath(kind)
end
local spec = dofile(config_root .. "/lua/plugins/codex-context.lua")
vim.fn.stdpath = stdpath
spec.opts.output_path = output
vim.go.loadplugins = true
require("lazy").setup({ spec }, {
  root = root .. "/lazy", lockfile = root .. "/lazy-lock.json",
  install = { missing = false }, checker = { enabled = false },
  change_detection = { enabled = false }, readme = { enabled = false },
})
assert(vim.fn.exists(":CodexContextRefresh") == 2)
assert(#read().instances == 1)
''')

    def worker(self, label):
        return self.start(r'''
local label = "''' + label + r'''"
vim.cmd.edit(root .. "/" .. label .. ".lua")
plugin.setup({ output_path = output, debounce_ms = 5, include = { treesitter = false } })
local tick = vim.uv.new_timer()
local disabled = false
tick:start(5, 5, vim.schedule_wrap(function()
  if vim.uv.fs_stat(root .. "/" .. label .. ".disable") then
    if not disabled then plugin.disable(); disabled = true end
  elseif vim.uv.fs_stat(root .. "/" .. label .. ".exit") then
    vim.cmd("qa!")
  else
    if disabled then plugin.enable(); disabled = false end
    plugin.refresh()
  end
end))
vim.wait(12000, function() return false end, 10)
error("worker timed out")
''')

    def test_concurrent_instances_cleanup_and_crash(self):
        first = self.worker("first")
        second = self.worker("second")
        self.wait_for(lambda: len(self.context()) == 2)
        for _ in range(60):
            instances = self.context()
            self.assertEqual({item["pid"] for item in instances}, {first.pid, second.pid})
            time.sleep(0.005)
        (self.root / "first.disable").touch()
        self.wait_for(lambda: [item["pid"] for item in self.context()] == [second.pid])
        (self.root / "first.disable").unlink()
        self.wait_for(lambda: len(self.context()) == 2)
        third = self.worker("third")
        self.wait_for(lambda: len(self.context()) == 3)
        (self.root / "third.exit").touch()
        third.communicate(timeout=3)
        self.assertEqual(third.returncode, 0)
        self.assertEqual({item["pid"] for item in self.context()}, {first.pid, second.pid})
        self.run_lua(r'''
local config = { output_path = output, include = {} }
require("nvim-codex-context.writer").update(config, { pid = vim.fn.getpid(), timestamp = os.time() }, 100)
''')
        second.kill()
        second.communicate(timeout=3)
        self.wait_for(lambda: all(item["pid"] != second.pid for item in self.context()))
        (self.root / "first.exit").touch()
        first.communicate(timeout=3)
        self.assertEqual(first.returncode, 0)
        self.assertFalse((self.root / "context.json").exists())
        self.assertFalse((self.root / "context.json.lock").exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
