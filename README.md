# mago.nvim

A Neovim plugin for [Mago](https://mago.carthage.software/), the blazing fast PHP toolchain written in Rust.

## Features

- **Format PHP files** with Mago's opinionated formatter
- **Format on save** (optional)
- **Format visual selections** or ranges
- **Auto-detection** of Mago executable (project or global)

## Requirements

- Neovim >= 0.10.0
- [Mago](https://mago.carthage.software/) installed either:
  - Globally in your `$PATH`
  - In your project via Composer: `composer require --dev carthage/mago`

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'calvinludwig/mago.nvim',
  ft = 'php',  -- Load only for PHP files
  opts = {
    format_on_save = false,  -- Enable auto-format on save
  },
}
```

## Configuration

Default configuration:

```lua
require('mago').setup({
  format_on_save = false,     -- Auto-format on save
  mago_path = nil,            -- Custom mago path (nil = auto-detect)
  notify_on_error = true,     -- Show vim.notify on error
  quickfix_on_error = true,   -- Populate quickfix on error
})
```

### Options

- `format_on_save` (boolean): Automatically format PHP files when saving
- `mago_path` (string|nil): Custom path to Mago executable. If `nil`, auto-detects from `vendor/bin/mago` or global `mago`
- `notify_on_error` (boolean): Show notification when formatting fails
- `quickfix_on_error` (boolean): Populate quickfix list with errors

## Usage

### Commands

- `:MagoFormat` - Format the current buffer
- `:MagoFormatRange` - Format a visual selection or range
- `:MagoInfo` - Show Mago executable path and version
- `:MagoToggleFormatOnSave` - Toggle format on save

### Keymaps

Add to your `init.lua`:

```lua
-- Format current buffer
vim.keymap.set('n', '<leader>mf', '<cmd>MagoFormat<cr>', { desc = 'Mago format' })

-- Format visual selection
vim.keymap.set('v', '<leader>mf', '<cmd>MagoFormatRange<cr>', { desc = 'Mago format range' })
```

### Format on Save

Enable in your setup:

```lua
require('mago').setup({
  format_on_save = true,
})
```

Or toggle dynamically:

```vim
:MagoToggleFormatOnSave
```

### Visual Range Formatting

1. Select lines in visual mode (`V`)
2. Run `:MagoFormatRange` or use your keymap

## Integration with Other Plugins

### conform.nvim

```lua
require('conform').setup({
  formatters_by_ft = {
    php = { 'mago' },
  },
  formatters = {
    mago = {
      command = function()
        return require('mago.executable').find() or 'mago'
      end,
      args = { 'fmt', '--stdin-input' },
      stdin = true,
    },
  },
})
```

## How It Works

1. **Executable Detection**: The plugin searches for Mago in this order:
   - Custom `mago_path` from config
   - `vendor/bin/mago` in your project (searches upward from current file)
   - Global `mago` in `$PATH`

2. **Formatting**: Runs `mago fmt --stdin-input`, passing your buffer content via stdin

## Troubleshooting

### Mago executable not found

Run `:MagoInfo` to check if Mago is detected. If not:

- Install globally: Follow [Mago installation guide](https://mago.carthage.software/)
- Install via Composer: `composer require --dev carthage/mago`
- Set custom path:

  ```lua
  require('mago').setup({
    mago_path = '/path/to/mago',
  })
  ```

### Formatting errors

- Check the quickfix list: `:copen`
- Ensure your PHP file has valid syntax
- Check Mago's configuration (`mago.toml` in your project root)

## Roadmap

Future features planned:

- Async formatting
- Linter integration
- Static analyzer integration
- Architectural guard integration

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - see LICENSE file for details

## Related Projects

- [Mago](https://mago.carthage.software/) - The Oxidized PHP Toolchain
- [carthage/mago](https://github.com/carthage/mago) - Mago on GitHub
