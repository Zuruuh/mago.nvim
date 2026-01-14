local M = {}

function M.format_filepath(filepath)
  local executable = require 'mago-nvim.executable'
  executable.run { 'fmt', filepath }
end

function M.format_stdin(input)
  local executable = require 'mago-nvim.executable'
  return executable.run({ 'fmt', '--stdin-input' }, { stdin = input })
end

return M
