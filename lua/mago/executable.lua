local M = {}

M.mago_path = nil

function M.init()
  local vendor_mago = vim.fn.findfile('vendor/bin/mago', '.;')
  if vendor_mago ~= '' then
    local full_path = vim.fn.fnamemodify(vendor_mago, ':p')
    if vim.fn.executable(full_path) == 1 then
      M.mago_path = full_path
      return true
    end
  end

  if vim.fn.executable 'mago' == 1 then
    M.mago_path = 'mago'
    return true
  end

  return false
end

function M.run(cmd, opts)
  if opts == nil then opts = {} end

  table.insert(cmd, 1, M.mago_path)
  opts.text = true

  local result = vim.system(cmd, opts):wait()

  if result.code == 0 and result.stdout then return result.stdout end

  vim.notify(string.format('[mago.nvim] Failed to run command: ' .. cmd[2], vim.log.levels.ERROR))
  vim.log(result.stderr, vim.log.levels.ERROR, { title = 'mago.nvim' })

  return nil
end

return M
