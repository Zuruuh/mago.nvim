# mago.nvim Implementation Plan

## Overview
A Neovim plugin to integrate Mago PHP toolchain (https://mago.carthage.software/). This initial version implements **formatting only**. Future versions will add linter, analyzer, and architectural guard features.

## User Requirements

### Format Triggers
1. Manual command: `:MagoFormat`
2. Format on save: Auto-format on BufWritePre (configurable)
3. Format range/selection: Visual mode formatting

### LSP Integration
- Standalone: Custom commands work independently
- LSP-compatible: Register as formatter for `vim.lsp.buf.format()`, conform.nvim, null-ls

### Error Handling
- Show `vim.notify()` notification on error
- Populate quickfix list with parseable errors
- Keep buffer unchanged on error

### Executable Discovery
1. Check `vendor/bin/mago` (Composer install)
2. Check global `mago` (in PATH)
3. Show helpful error if not found

## Mago Formatter CLI

**Command**: `mago fmt --stdin-input`
- Reads PHP code from stdin
- Outputs formatted code to stdout
- Exit code: 0 = success, non-zero = error
- Errors printed to stderr

## File Structure

```
mago.nvim/
├── lua/
│   └── mago/
│       ├── init.lua          # Main module, setup() function
│       ├── config.lua         # Configuration management
│       ├── executable.lua     # Find mago binary
│       ├── formatter.lua      # Core formatting logic
│       ├── lsp.lua            # LSP formatter integration
│       ├── errors.lua         # Error parsing & quickfix
│       └── commands.lua       # User commands
├── plugin/
│   └── mago.vim              # Plugin initialization
├── doc/
│   └── mago.txt              # Vim help documentation
├── .gitignore
├── README.md
└── PLAN.md (this file)
```

## Module Details

### 1. `lua/mago/init.lua`
**Purpose**: Main plugin entry point and setup

**Key functions**:
```lua
M.setup(opts)
  -- Merges user config with defaults
  -- Initializes plugin
  -- Sets up autocommands if format_on_save enabled
```

**Exports**:
- `setup()` - User configuration function

### 2. `lua/mago/config.lua`
**Purpose**: Configuration storage and defaults

**Structure**:
```lua
M.defaults = {
  format_on_save = false,     -- Auto-format on save
  mago_path = nil,            -- Custom mago path (nil = auto-detect)
  notify_on_error = true,     -- Show vim.notify on error
  quickfix_on_error = true,   -- Populate quickfix on error
}

M.options = {}  -- Current config (merged with user options)

M.set(opts)     -- Merge user config
M.get()         -- Get current config
```

### 3. `lua/mago/executable.lua`
**Purpose**: Find mago executable

**Key functions**:
```lua
M.find()
  -- 1. Check config.options.mago_path (if set)
  -- 2. Check vim.fn.findfile('vendor/bin/mago', '.;')
  -- 3. Check vim.fn.executable('mago')
  -- Returns: path to mago or nil

M.get_or_error()
  -- Calls find(), shows error if not found
  -- Returns: path or nil (with notification)

M.get_version(mago_path)
  -- Runs: mago --version
  -- Returns: version string
```

### 4. `lua/mago/formatter.lua`
**Purpose**: Core formatting logic

**Key functions**:
```lua
M.format_buffer(bufnr, start_line, end_line)
  -- bufnr: buffer number (0 = current)
  -- start_line, end_line: nil = entire buffer, or range
  -- 1. Get mago path via executable.find()
  -- 2. Get buffer lines
  -- 3. Run: mago fmt --stdin-input
  -- 4. Pass lines as stdin
  -- 5. Capture stdout (formatted) and stderr (errors)
  -- 6. On success: Replace buffer content
  -- 7. On error: Call errors.handle()
  -- Returns: true on success, false on error

M.format_range(bufnr, start_line, end_line)
  -- Format specific line range
  -- Wraps format_buffer with range params
```

**Implementation details**:
- Use `vim.system()` to run mago
- Join buffer lines with `\n`
- Split stdout by `\n` for new lines
- Preserve cursor position with `vim.api.nvim_win_get_cursor()`
- Set buffer lines with `vim.api.nvim_buf_set_lines()`

### 5. `lua/mago/lsp.lua`
**Purpose**: LSP formatter integration

**Key functions**:
```lua
M.setup()
  -- Registers mago as LSP formatter
  -- Makes it available to vim.lsp.buf.format()

M.format(bufnr)
  -- LSP-compatible formatter function
  -- Signature matches LSP formatter interface
  -- Calls formatter.format_buffer()
```

**conform.nvim integration**:
```lua
-- Users can add to their conform config:
formatters_by_ft = {
  php = { "mago" },
}

formatters = {
  mago = {
    command = function()
      return require("mago.executable").find() or "mago"
    end,
    args = { "fmt", "--stdin-input" },
    stdin = true,
  },
}
```

### 6. `lua/mago/errors.lua`
**Purpose**: Parse errors and populate quickfix

**Key functions**:
```lua
M.handle(stderr, bufnr)
  -- Parse stderr from mago
  -- 1. Show vim.notify() with error summary
  -- 2. Parse error format to extract:
  --    - filename
  --    - line number
  --    - column number
  --    - error message
  -- 3. Build quickfix list entries
  -- 4. Call vim.fn.setqflist()

M.parse_error(error_text)
  -- Parse single error line
  -- Returns: { filename, lnum, col, text }
```

**Error format** (to be determined from testing):
- Common formats: `file.php:15:3: error message`
- May need to test mago error output format

### 7. `lua/mago/commands.lua`
**Purpose**: Define user commands

**Commands**:
```lua
-- :MagoFormat - Format entire buffer
vim.api.nvim_create_user_command('MagoFormat', function()
  require('mago.formatter').format_buffer(0)
end, { desc = 'Format current buffer with Mago' })

-- :MagoFormatRange - Format visual selection
vim.api.nvim_create_user_command('MagoFormatRange', function(opts)
  require('mago.formatter').format_range(0, opts.line1, opts.line2)
end, { range = true, desc = 'Format selected range with Mago' })

-- :MagoInfo - Show plugin info
vim.api.nvim_create_user_command('MagoInfo', function()
  local exe = require('mago.executable')
  local path = exe.find()
  if path then
    local version = exe.get_version(path)
    print(string.format('Mago: %s\nVersion: %s', path, version))
  else
    print('Mago executable not found')
  end
end, { desc = 'Show Mago information' })
```

### 8. `plugin/mago.vim`
**Purpose**: Plugin initialization (loads once)

**Content**:
```vim
" Prevent loading twice
if exists('g:loaded_mago')
  finish
endif
let g:loaded_mago = 1

" Load Lua commands
lua require('mago.commands')
```

### 9. `doc/mago.txt`
**Purpose**: Vim help documentation

**Sections**:
- Introduction
- Requirements
- Installation
- Configuration (setup options)
- Commands
- Mappings (example keybindings)
- FAQ
- License

## Implementation Order

### Phase 1: Core Infrastructure
1. Create directory structure
2. `lua/mago/config.lua` - Configuration defaults
3. `lua/mago/executable.lua` - Executable finder
4. `lua/mago/init.lua` - Basic setup() function
5. Test: Verify executable detection works

### Phase 2: Basic Formatting
6. `lua/mago/formatter.lua` - Format buffer function
7. `lua/mago/commands.lua` - :MagoFormat command
8. `plugin/mago.vim` - Load commands
9. Test: Format a PHP file manually

### Phase 3: Error Handling
10. `lua/mago/errors.lua` - Error parsing
11. Update `formatter.lua` to use error handler
12. Test: Trigger errors, check quickfix and notifications

### Phase 4: Advanced Features
13. Format range support in `formatter.lua`
14. `:MagoFormatRange` command
15. Format on save autocommand in `init.lua`
16. Test: Visual selection formatting, auto-save

### Phase 5: LSP Integration
17. `lua/mago/lsp.lua` - LSP formatter
18. Document conform.nvim integration
19. Test: vim.lsp.buf.format() works

### Phase 6: Documentation
20. `README.md` - Installation, usage, examples
21. `doc/mago.txt` - Full Vim help docs
22. `.gitignore` - Standard Vim plugin ignores

## Key Implementation Patterns

### Running Mago
```lua
local mago_path = require('mago.executable').find()
local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
local input = table.concat(lines, '\n')

local result = vim.system(
  { mago_path, 'fmt', '--stdin-input' },
  { stdin = input, text = true }
):wait()

if result.code == 0 then
  local formatted = vim.split(result.stdout, '\n')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted)
else
  require('mago.errors').handle(result.stderr, 0)
end
```

### Format on Save
```lua
-- In init.lua setup()
if config.options.format_on_save then
  vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = '*.php',
    callback = function()
      require('mago.formatter').format_buffer(0)
    end,
    group = vim.api.nvim_create_augroup('MagoFormat', { clear = true }),
  })
end
```

### Visual Range Formatting
```lua
-- In commands.lua
vim.keymap.set('v', '<leader>mf', function()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  require('mago.formatter').format_range(0, start_line, end_line)
end, { desc = 'Format selection with Mago' })
```

## Configuration Example

User's init.lua:
```lua
require('mago').setup({
  format_on_save = true,
  mago_path = '/custom/path/to/mago',  -- Optional
})

-- Optional keybindings
vim.keymap.set('n', '<leader>mf', '<cmd>MagoFormat<cr>', { desc = 'Mago format' })
vim.keymap.set('v', '<leader>mf', '<cmd>MagoFormatRange<cr>', { desc = 'Mago format range' })
```

## Testing Approach

### Manual Testing Checklist
1. ✓ Mago executable detection (vendor/bin, global)
2. ✓ Format entire PHP buffer
3. ✓ Format visual selection
4. ✓ Format on save (when enabled)
5. ✓ Error handling (invalid PHP)
6. ✓ Quickfix population
7. ✓ vim.notify messages
8. ✓ :MagoInfo command
9. ✓ LSP integration (if using conform.nvim)
10. ✓ Cursor position preservation
11. ✓ Undo/redo works correctly

### Test Files Needed
- `test.php` - Valid PHP file for formatting
- `invalid.php` - Invalid PHP to test error handling
- `composer.json` - Project with vendor/bin/mago

## Future Enhancements (Not in v1)

- Linter integration (`:MagoLint`)
- Analyzer integration (`:MagoAnalyze`)
- Architectural guard (`:MagoGuard`)
- Telescope integration for diagnostics
- Status line integration
- Configuration UI
- Async formatting
- Format on save with debouncing
- Format ranges by AST nodes (format function, class, etc.)

## Open Questions

1. **Error format**: Need to test actual mago error output format to parse correctly
2. **Range formatting**: Can mago handle partial PHP code? May need full file context
3. **Performance**: Is stdin/stdout fast enough for large files?
4. **Configuration**: Does mago.toml need to be in specific location?

## Notes

- Keep implementation simple - this is user's first plugin
- Follow Neovim best practices (use Lua, not VimScript)
- Make it easy to extend for future features (linter, analyzer)
- Prioritize good error messages for debugging
- Document everything clearly for PHP developers new to Neovim
