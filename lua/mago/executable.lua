local M = {}

function M.find()
  local vendor_mago = vim.fn.findfile('vendor/bin/mago', '.;')
  if vendor_mago ~= '' then
    local full_path = vim.fn.fnamemodify(vendor_mago, ':p')
    if vim.fn.executable(full_path) == 1 then return full_path end
  end

  if vim.fn.executable 'mago' == 1 then return 'mago' end

  return nil
end

function M.get_or_error()
  local mago_path = M.find()

  if not mago_path then
    vim.notify(
      '[mago.nvim] Mago executable not found.\n'
        .. 'Install it globally or via Composer in your project:\n'
        .. '  composer require --dev carthage/mago',
      vim.log.levels.ERROR
    )
    return nil
  end

  return mago_path
end

function M.get_version(mago_path)
  if not mago_path then return nil end

  local result = vim.system({ mago_path, '--version' }, { text = true }):wait()

  if result.code == 0 then
    local version = result.stdout:match '[%d%.]+' or result.stdout:gsub('\n', '')
    return version
  end

  return nil
end

return M
