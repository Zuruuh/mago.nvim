# AGENTS.md - Guide for AI Coding Agents

This document provides essential information for AI coding agents working on mago.nvim.

## Project Overview

mago.nvim is a Neovim plugin for [Mago](https://mago.carthage.software/), the blazing fast PHP toolchain written in Rust. It provides formatting, linting, and diagnostics for PHP files through a fake LSP server implementation.

**Status**: Under active development, not ready for production use.

## Project Structure

```
mago.nvim/
├── lua/mago/           # Core Lua modules
│   ├── init.lua        # Plugin entry point and setup
│   ├── server.lua      # Fake LSP server implementation
│   ├── formatter.lua   # Format PHP code via Mago
│   ├── linter.lua      # Lint PHP code and manage diagnostics
│   ├── executable.lua  # Find and validate Mago executable
│   ├── errors.lua      # Error parsing and quickfix handling
│   └── commands.lua    # User commands (:MagoFormat, :MagoInfo, etc.)
├── plugin/mago.vim     # Vim plugin loader
├── .stylua.toml        # StyLua formatter config
└── README.md           # User documentation
```

## Build/Test/Lint Commands

This is a Lua-based Neovim plugin with no build step. Testing and linting are done manually.

### Formatting Lua Code

```bash
# Format all Lua files with StyLua
stylua .

# Check formatting without modifying files
stylua --check .
```

### Manual Testing

Since this is a Neovim plugin, testing is done by:

1. Loading the plugin in Neovim (use a local plugin manager config)
2. Opening a PHP file
3. Running commands like `:MagoFormat`, `:MagoInfo`, `:MagoFixLintErrors`
4. Verifying diagnostics appear on save

### Testing Individual Modules

Load individual modules in Neovim command mode:

```vim
:lua require('mago.linter').lint(0)
:lua require('mago.formatter').format_buffer(0)
:lua require('mago.executable').find()
```

## Code Style Guidelines

### General Principles

- Write clean, readable Lua code following Neovim plugin conventions
- Prioritize clarity over cleverness
- Use descriptive variable and function names
- Keep functions focused on a single responsibility

### Formatting (Enforced by .stylua.toml)

- **Line width**: 120 characters
- **Indentation**: 2 spaces (not tabs)
- **Line endings**: Unix (LF)
- **Quote style**: Auto-prefer single quotes
- **Call parentheses**: No single table argument parentheses
- **No call parentheses**: true (prefer `require 'module'` over `require('module')`)

### Module Structure

All modules follow this pattern:

```lua
-- Private helper functions at the top
local function helper_function()
  -- Implementation
end

-- Public API in M table
local M = {}

function M.public_function()
  -- Implementation
end

return M
```

### Naming Conventions

- **Files**: lowercase with underscores (e.g., `executable.lua`, `commands.lua`)
- **Functions**: snake_case (e.g., `format_buffer`, `get_mago_executable`)
- **Local functions**: snake_case with descriptive names
- **Constants**: UPPER_SNAKE_CASE for true constants
- **Module table**: Always use `M` for the public module table
- **Variables**: snake_case, descriptive names

### Imports and Requires

```lua
-- Prefer concise require syntax without parentheses
local linter = require 'mago.linter'
local formatter = require 'mago.formatter'

-- Use parentheses when chaining or for clarity with complex expressions
local config = require('mago.config').get()
```

### Error Handling

- **Always validate inputs**: Check bufnr, filepath, executable existence
- **Fail gracefully**: Use `vim.notify()` with appropriate log levels
- **Return nil or false on failure**: Don't throw errors unless critical
- **Use pcall for risky operations**: Especially for JSON parsing

Example pattern:

```lua
local function validate_and_get_path(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    vim.notify('[mago.nvim] Invalid buffer', vim.log.levels.ERROR)
    return nil
  end
  
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == '' then
    vim.notify('[mago.nvim] Buffer not saved', vim.log.levels.WARN)
    return nil
  end
  
  return filepath
end
```

### Type Annotations and Documentation

Use comment-based documentation for public functions:

```lua
-- Format the specified buffer using Mago
-- @param bufnr number: Buffer number (0 for current buffer)
-- @return boolean: true if formatting succeeded, false otherwise
function M.format_buffer(bufnr)
  -- Implementation
end
```

### Vim API Conventions

- Use `vim.api.*` for low-level operations
- Use `vim.*` helpers when available (e.g., `vim.notify`, `vim.split`)
- Always use `vim.api.nvim_*` functions over deprecated `vim.fn.*` where possible
- Prefer `vim.system()` over `vim.fn.system()` for external commands

### Buffer and Window Handling

- Default to current buffer: `bufnr = bufnr or 0` then normalize
- Validate buffer validity before operations
- Save and restore cursor position for formatting operations
- Use `pcall()` when setting cursor position (may fail if line deleted)

### Diagnostics

- Use a dedicated namespace: `vim.api.nvim_create_namespace('mago_linter')`
- Clear diagnostics on buffer changes
- Set diagnostics with proper severity mapping
- Include source and code in diagnostic entries

### LSP Server Implementation

The fake LSP server pattern:

```lua
function server.request(method, params, callback)
  local methods = {
    ['methodName'] = function(params, callback)
      -- Handle request
      callback(nil, result)  -- (error, result)
    end,
  }
  
  local handler = methods[method]
  if handler then
    handler(params, callback)
  else
    callback(nil, nil)  -- Default: no error, no result
  end
end
```

### Command Definitions

```lua
vim.api.nvim_create_user_command('CommandName', function()
  require('mago.module').function_name(0)
end, {
  desc = 'Brief description of what this command does',
})
```

## Common Patterns

### External Command Execution

```lua
local result = vim.system({ mago_path, 'fmt', '--stdin-input' }, {
  stdin = input,
  text = true,
}):wait()

if result.code == 0 then
  -- Success: use result.stdout
else
  -- Failure: handle result.stderr
end
```

### JSON Parsing (with error handling)

```lua
local success, data = pcall(vim.json.decode, json_output)
if not success then
  vim.notify('[mago.nvim] Failed to parse JSON', vim.log.levels.ERROR)
  return nil
end
```

## Git Workflow

### Commit Messages

Follow conventional commit format:

- `feat:` - New features
- `fix:` - Bug fixes
- `refact:` - Refactoring
- `docs:` - Documentation updates
- `chore:` - Maintenance tasks

Examples from project history:
- `feat: working linter`
- `fix: server module`
- `refact: formatter`

## Common Tasks

### Adding a New Command

1. Define the command in `lua/mago/commands.lua`
2. Implement the logic in the appropriate module
3. Update README.md with command documentation

### Adding New Mago Features

1. Implement the core logic in a new or existing module
2. Wire it into the LSP server if needed (in `server.lua`)
3. Add user commands if appropriate
4. Test manually with a PHP file

### Debugging

- Use `:messages` to see notification history
- Use `:lua print(vim.inspect(value))` to debug Lua values
- Check `:MagoInfo` to verify Mago executable is found
- Use `:copen` to view quickfix list for errors

## Dependencies

- **Runtime**: Neovim >= 0.10.0
- **External**: Mago PHP toolchain (found via vendor/bin/mago or $PATH)
- **Development**: StyLua for code formatting

## Important Notes

- This plugin creates a "fake" LSP server that runs in-process
- The LSP server is attached to all PHP buffers on FileType autocmd
- Formatting can use stdin (for unsaved buffers) or filepath (for saved buffers)
- Linting requires the buffer to be saved to disk
- All Mago operations are synchronous (using `:wait()` on vim.system)
