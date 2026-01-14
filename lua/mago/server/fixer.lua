local M = {}

function M.fix(bufnr, rule)
  local lint = require 'mago.run.lint'
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  print(rule)

  local is_modified = vim.bo[bufnr].modified

  if is_modified or not filepath then
    vim.notify '[mago.nvim] Save the file before fixing the issues'
    return
  end
  local result

  if rule == nil then
    result = lint.fix_all(filepath)
  else
    result = lint.fix_rule(filepath, rule)
  end

  vim.print(result)

  vim.api.nvim_buf_call(bufnr, function() vim.cmd 'edit!' end)

  vim.notify('[mago.nvim] ' .. result)
end

return M
