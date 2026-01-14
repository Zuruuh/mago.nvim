local M = {}

local severity_map = {
  Error = vim.diagnostic.severity.ERROR,
  Warning = vim.diagnostic.severity.WARN,
  Help = vim.diagnostic.severity.HINT,
  Note = vim.diagnostic.severity.INFO,
}

local function get_range_from_span(span)
  local start_line = span.start.line
  local end_line = span['end'].line
  local start_character = span.start.offset - vim.api.nvim_buf_get_offset(0, start_line)
  local end_character = span['end'].offset - vim.api.nvim_buf_get_offset(0, end_line)

  return {
    ['start'] = { line = start_line, character = start_character },
    ['end'] = { line = end_line, character = end_character },
  }
end

local function convert_issue_to_diagnostic(issue)
  local span = issue.annotations[1].span

  return {
    range = get_range_from_span(span),
    severity = severity_map[issue.level],
    message = string.format('[%s] %s', issue.code, issue.message),
    codeDescription = issue.code,
    source = 'mago.nvim',
  }
end

local function get_diagnostics_from_mago_issues(issues)
  local diagnostics = vim.tbl_map(convert_issue_to_diagnostic, issues or {})
  return diagnostics
end

function M.publish(uri, dispatchers)
  local filepath = vim.uri_to_fname(uri)
  local issues = require('mago.run.lint').check(filepath)

  dispatchers.notification('textDocument/publishDiagnostics', {
    uri = uri,
    diagnostics = get_diagnostics_from_mago_issues(issues),
  })
end

return M
