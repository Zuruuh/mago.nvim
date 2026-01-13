local function create_server(dispatchers)
  local server = {}
  local closing = false

  function server.request(m, p, c)
    local methods = {
      ['initialize'] = function(_, callback)
        callback(nil, {
          capabilities = {
            codeActionProvider = true,
            textDocumentSync = 1,
            documentFormattingProvider = true,
          },
        })
      end,

      ['textDocument/formatting'] = function(params, callback)
        -- formatter.format_buffer(vim.uri_to_bufnr(params.textDocument.uri))
        callback(nil, {})
      end,

      ['textDocument/codeAction'] = function(params, callback)
        vim.notify 'Code Actions requested'
        local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
        local actions = {}

        if vim.bo[bufnr].filetype ~= 'php' then
          callback(nil, actions)
          return
        end

        table.insert(actions, {
          title = 'Fix all Mago issues in file',
          kind = 'quickfix',
          command = {
            title = 'Fix all Mago issues',
            command = 'mago.fix_all',
            arguments = { bufnr },
          },
        })

        callback(nil, actions)
      end,

      ['shutdown'] = function(_, callback)
        closing = true
        callback(nil, nil)
      end,
    }

    local met = methods[m]

    if met then
      met(p, c)
      return
    end

    c(nil, nil)
  end

  local function refresh_diagnostics(uri)
    local filepath = vim.uri_to_fname(uri)
    local issues = require('mago.run.lint').check(filepath)

    dispatchers.notification('textDocument/publishDiagnostics', {
      uri = uri,
      diagnostics = require('mago.server.diagnostics').get_diagnostics_from_mago_issues(issues),
    })
  end

  function server.notify(m, p)
    local methods = {
      ['textDocument/didOpen'] = function(params)
        refresh_diagnostics(params.textDocument.uri)
        --
      end,

      ['textDocument/didSave'] = function(params)
        refresh_diagnostics(params.textDocument.uri)
        --
      end,

      ['textDocument/didChange'] = function(params) end,

      ['textDocument/didClose'] = function(_) end,
    }

    local met = methods[m]

    if met then met(p) end
  end

  function server.is_closing() return closing end

  function server.terminate() closing = true end

  return server
end

local M = {}

M.setup = function()
  local client = vim.lsp.start {
    name = 'mago.nvim',
    cmd = create_server,
    root_dir = vim.fn.getcwd(),
  }

  if not client then
    vim.notify('[mago.nvim] Failed to start LSP client', vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'php',
    callback = function() vim.lsp.buf_attach_client(0, client) end,
    desc = 'Attach mago.nvim LSP client to PHP buffers',
  })

  vim.lsp.commands['mago.fix_all'] = function(command)
    local bufnr = command.arguments[1]
    require('mago.linter').fix_all(bufnr)
  end

  vim.lsp.commands['mago.fix_rule'] = function(command)
    local bufnr = command.arguments[1]
    local rule_code = command.arguments[2]
    require('mago.linter').fix_rule(bufnr, rule_code)
  end

  vim.lsp.commands['mago.explain_rule'] = function(command)
    local rule_code = command.arguments[1]
    require('mago.linter').show_rule_explanation(rule_code)
  end
end

return M
