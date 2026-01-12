local M = {}

function M.parse_error(error_line)
  if not error_line or error_line == '' then return nil end

  local filename, lnum, col, text = error_line:match '^(.-)%:(%d+)%:(%d+)%:%s*(.*)$'
  if filename and lnum and col and text then
    return {
      filename = filename,
      lnum = tonumber(lnum),
      col = tonumber(col),
      text = text,
    }
  end

  filename, lnum, text = error_line:match '^(.-)%:(%d+)%:%s*(.*)$'
  if filename and lnum and text then
    return {
      filename = filename,
      lnum = tonumber(lnum),
      col = 1,
      text = text,
    }
  end

  return {
    filename = '',
    lnum = 1,
    col = 1,
    text = error_line,
  }
end

function M.handle(stderr, bufnr)
  if not stderr or stderr == '' then stderr = 'Unknown error occurred' end

  local lines = vim.split(stderr, '\n', { plain = true })
  local first_line = lines[1] or 'Formatting failed'

  vim.notify(string.format('[mago.nvim] %s', first_line), vim.log.levels.ERROR)

  local qf_entries = {}
  local lines = vim.split(stderr, '\n', { plain = true })

  for _, line in ipairs(lines) do
    local entry = M.parse_error(line)
    if entry and entry.text ~= '' then
      if entry.filename == '' and bufnr then entry.bufnr = bufnr end
      table.insert(qf_entries, entry)
    end
  end

  if #qf_entries > 0 then
    vim.fn.setqflist(qf_entries, 'r')
    vim.notify(
      string.format('[mago.nvim] %d error(s) added to quickfix list. Use :copen to view.', #qf_entries),
      vim.log.levels.INFO
    )
  end
end

return M
