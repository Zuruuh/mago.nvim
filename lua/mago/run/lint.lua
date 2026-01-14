local M = {}

function M.check(filepath)
  local executable = require 'mago.executable'
  local output = executable.run { 'lint', '--reporting-format', 'json', filepath }

  if output == nil or output == '' then return {} end

  local decoded = vim.json.decode(output)

  return decoded.issues
end

function M.explain(rule)
  local executable = require 'mago.executable'
  return executable.run { 'lint', '--explain', rule }
end

return M
