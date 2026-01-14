local M = {}

local function mago() return require 'mago.executable' end

function M.check(filepath)
  local output = mago().run { 'lint', '--reporting-format', 'json', filepath }
  if output == nil or output == '' then return {} end
  local decoded = vim.json.decode(output)
  return decoded.issues
end

function M.explain(rule)
  --
  return mago().run { 'lint', '--explain', rule }
end

function M.fix_all(filepath)
  --
  return mago().run { 'lint', '--fix', filepath, '--format-after-fix' }
end

function M.fix_rule(filepath, rule)
  --
  return mago().run { 'lint', '--fix', filepath, '--only', rule, '--format-after-fix' }
end

return M
