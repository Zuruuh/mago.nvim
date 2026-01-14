local M = {}

function M.popup_explain(rule)
  local output = require('mago-nvim.run.lint').explain(rule)

  if output == nil then
    -- vim.notify(string.format('[mago.nvim] Could not found [%s] rule', rule), vim.log.levels.WARN)
    return
  end

  require('mago-nvim.popup').show(vim.split('  ' .. vim.fn.trim(output), '\n'))
end

return M
