local root = vim.fn.getcwd()
vim.opt.rtp:prepend(root .. "/vendor/codeowners.nvim")
local owners = require("codeowners")
owners.setup({ icon = "Owners:", separator = ", " })

local fixture = vim.fn.tempname()
local repo = fixture .. "/repo with spaces;literal"
vim.fn.mkdir(repo .. "/docs", "p")
vim.fn.mkdir(repo .. "/packs/team/nested", "p")
vim.fn.mkdir(repo .. "/other", "p")
vim.fn.system({ "git", "init", "--quiet", repo })
assert(vim.v.shell_error == 0, "fixture git init failed")
vim.fn.writefile({
  "* @default",
  "packs/team/**/* @team",
  "**/es.yml @translations",
  "/Rakefile @framework",
  "special/file.rb @one @two # comment",
  "literal/a+b.rb @literal",
  "unowned.rb",
}, repo .. "/docs/CODEOWNERS")

local original_systemlist = vim.fn.systemlist
local calls = 0
vim.fn.systemlist = function(argv)
  assert(type(argv) == "table", "Git must not run through a shell")
  calls = calls + 1
  return original_systemlist(argv)
end

local function check(path, expected)
  if path:sub(1, #fixture) == fixture then
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  end
  vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(true, false))
  vim.api.nvim_buf_set_name(0, path)
  assert(owners.codeowners() == expected, path .. ": " .. owners.codeowners())
end

check(repo .. "/packs/team/file.rb", "Owners: team")
check(repo .. "/packs/team/nested/file.rb", "Owners: team")
check(repo .. "/es.yml", "Owners: translations")
check(repo .. "/other/es.yml", "Owners: translations")
check(repo .. "/Rakefile", "Owners: framework")
check(repo .. "/other/Rakefile", "Owners: default")
check(repo .. "/special/file.rb", "Owners: one, two")
check(repo .. "/other/special/file.rb", "Owners: default")
check(repo .. "/literal/a+b.rb", "Owners: literal")
check(repo .. "/unowned.rb", "")
local before = calls
owners.codeowners()
assert(calls == before, "redraw must use cached owners")
vim.fn.writefile({ "* @updated" }, repo .. "/docs/CODEOWNERS")
vim.api.nvim_exec_autocmds("FocusGained", {})
assert(owners.codeowners() == "Owners: updated", "CODEOWNERS changes must refresh")
vim.fn.mkdir(repo .. "/.github", "p")
vim.fn.writefile({ "* @github" }, repo .. "/.github/CODEOWNERS")
vim.api.nvim_exec_autocmds("FocusGained", {})
assert(owners.codeowners() == "Owners: github", "GitHub file must take precedence")
vim.fn.mkdir(fixture .. "/plain", "p")
check(fixture .. "/plain/file.rb", "")
vim.bo.buftype = "nofile"
assert(owners.codeowners() == "", "special buffers must stay empty")
vim.fn.systemlist = original_systemlist

check(vim.fn.expand("~/Documents/buk/buk-webapp/Rakefile"), "Owners: bukhr/framework")
print("buk-webapp/Rakefile: " .. owners.codeowners())

local spec = dofile(root .. "/lua/plugins/statusline.lua")
assert(spec.dependencies[1] == "codeowners.nvim")
assert(spec.opts.sections.lualine_c[2]() == "Owners: bukhr/framework")
vim.opt.rtp:prepend(vim.fn.expand("~/.local/share/nvim/lazy/lualine.nvim"))
require("lualine").setup(spec.opts)
vim.o.columns = 180
local rendered = vim.api.nvim_eval_statusline(require("lualine").statusline(true), { maxwidth = 180 }).str
assert(rendered:find("Owners: bukhr/framework", 1, true), rendered)
print("Rendered statusline: " .. rendered)
print("PASS: matching, shell safety, cache, discovery and lualine rendering")
