local M = {}

local functions = {
  function_declaration = true, function_definition = true,
  method_definition = true, method_declaration = true,
  constructor_declaration = true, function_item = true,
  arrow_function = true, lambda = true, method = true, singleton_method = true,
}
local classes = {
  class_declaration = true, class_definition = true, struct_declaration = true,
  struct_item = true, interface_declaration = true, impl_item = true,
  class = true, module = true,
}

local function name(node, buf)
  local field = node:field("name")[1]
  if field then
    return vim.treesitter.get_node_text(field, buf)
  end
  local parent = node:parent()
  if parent and (parent:type() == "variable_declarator" or parent:type() == "assignment_statement") then
    field = parent:field("name")[1] or parent:child(0)
    if field then
      return vim.treesitter.get_node_text(field, buf)
    end
  end
end

function M.get_context()
  -- Parser availability and grammar differences must never interrupt editing.
  local ok, result = pcall(function()
    local buf = vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(buf)
    if not parser then
      return
    end
    parser:parse()
    local node = vim.treesitter.get_node({ bufnr = buf })
    local context = {}
    while node do
      local kind = node:type()
      if functions[kind] and not context["function"] then
        context["function"] = name(node, buf)
      elseif classes[kind] and not context.class then
        context.class = name(node, buf)
      end
      node = node:parent()
    end
    return next(context) and context or nil
  end)
  return ok and result or nil
end

return M
