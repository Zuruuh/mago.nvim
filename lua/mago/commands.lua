vim.api.nvim_create_user_command('MagoInfo', function()
  local exe = require 'mago.executable'
  local path = exe.find()

  if path then
    local version = exe.get_version(path)
    print '=== Mago.nvim Info ==='
    print('Mago path: ' .. path)
    print('Version: ' .. (version or 'unknown'))

    local ns = require('mago.linter').get_namespace()
    local bufnr = vim.api.nvim_get_current_buf()
    local diagnostics = vim.diagnostic.get(bufnr, { namespace = ns })
    print('Current buffer diagnostics: ' .. #diagnostics)
  else
    print '=== Mago.nvim Info ==='
    print 'Mago executable: NOT FOUND'
    print 'Install Mago globally or via Composer:'
    print '  composer require --dev carthage/mago'
  end
end, {
  desc = 'Show Mago information',
})

vim.api.nvim_create_user_command('MagoFormat', function() require('mago.formatter').format_buffer(0) end, {
  desc = 'Format current buffer with Mago',
})

vim.api.nvim_create_user_command('MagoFixAll', function() require('mago.linter').fix_all(0) end, {
  desc = 'Fix all linting errors in the current buffer with Mago',
})

vim.api.nvim_create_user_command('MagoExplainRule', function(opts)
  local rule = vim.fn.trim(opts.args)

  if rule == '' then
    vim.notify('[mago.nvim] Specify rule by parameter (:MagoExplainRule <rule>)', vim.log.levels.INFO)
    return
  end

  require('mago.server.rules').popup_explain(rule)
end, {
  nargs = '?',
  desc = 'Explain a Mago linter rule',
})
