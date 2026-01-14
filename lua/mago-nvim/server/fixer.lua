local M = {}

function M.fix(bufnr, rule)
  local lint = require 'mago-nvim.run.lint'
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  local is_modified = vim.bo[bufnr].modified

  if is_modified or not filepath then
    vim.notify '[mago.nvim] Save the file before fixing the issues'
    return
  end

  if rule == nil then
    lint.fix_all(filepath)
  else
    lint.fix_rule(filepath, rule)
  end

  vim.api.nvim_buf_call(bufnr, function() vim.cmd 'edit!' end)
end

return M
