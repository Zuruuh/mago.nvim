local M = {}

function M.setup()
  local exe = require 'mago.executable'
  if not exe.init() then
    vim.notify('[mago.nvim] Mago executable not found', vim.log.levels.ERROR)
    return
  end

  require('mago.server').setup()
  -- require 'mago.commands'
end

return M
