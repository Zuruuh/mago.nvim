local M = {}

function M.setup()
  local exe = require 'mago-nvim.executable'
  if not exe.init() then
    -- vim.notify('[mago.nvim] Mago executable not found', vim.log.levels.ERROR)
    return
  end

  require('mago-nvim.server').setup()
  require 'mago-nvim.commands'
end

return M
