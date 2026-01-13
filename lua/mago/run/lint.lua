local M = {}

function M.check(filepath)
  local executable = require 'mago.executable'
  local output = executable.run { 'lint', '--reporting-format', 'json', filepath }

  if output == nil or output == '' then return {} end

  local decoded = vim.json.decode(output)

  return decoded.issues
end

function M.fix(uri)
  local executable = require 'mago.executable'
  local filepath = require('mago.support').path_from_uri(uri)

  local output = executable.run { 'lint', '--fix', '--format-after-fix', filepath }
end

return M
