# snacks-lf.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.9+-green.svg?style=flat-square&logo=neovim)](https://neovim.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)

A Neovim plugin that integrates [lf](https://github.com/gokcehan/lf) file manager with [snacks.nvim](https://github.com/folke/snacks.nvim) terminal.

## Features

- 🚀 Floating terminal integration with lf
- ⌨️ Smart keybindings for opening files (`<C-t>`, `<C-s>`, `<C-v>`)
- 📂 Opens current file location or working directory
- 🔄 Handles file renames and buffer cleanup
- 🎨 Configurable window size and opener modes
- 📐 Auto-resize handling for terminal window changes

## Requirements

- Neovim >= 0.9.0
- [snacks.nvim](https://github.com/folke/snacks.nvim)
- [lf](https://github.com/gokcehan/lf) file manager installed

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "jackielii/snacks-lf.nvim",
  dependencies = {
    "folke/snacks.nvim",
  },
  keys = {
    {
      "<leader>l",
      function()
        require("snacks-lf").toggle()
      end,
      desc = "Lf file manager",
    },
  },
  opts = {
    -- Configuration options (see below)
  },
}
```

Or use the provided lazy spec:

```lua
require("snacks-lf.lazy")
```

## Usage

Press `<leader>l` (or your configured key) to open lf in a floating terminal.

### Keybindings inside lf

- `<C-t>` - Open file in new tab
- `<C-s>` - Open file in horizontal split
- `<C-v>` - Open file in vertical split
- `l` - Open file with selected mode (press after setting mode with above keys)
- `q` - Quit lf without opening files

## Configuration

### Global Configuration

Configure defaults using the `opts` table in lazy.nvim:

```lua
{
  "jackielii/snacks-lf.nvim",
  dependencies = { "folke/snacks.nvim" },
  keys = { { "<leader>l", function() require("snacks-lf").toggle() end, desc = "Lf" } },
  opts = {
    -- Window options
    width = 0.8,              -- Window width (default: 0.8)
    height = 0.9,             -- Window height (default: 0.9)
    title = "Lf",             -- Terminal title (default: "Lf")
    position = "float",       -- Terminal position: "float", "bottom", "top", "left", "right" (default: "float")

    -- Behavior options
    opener = "edit",          -- Default opener mode (default: "edit")
    auto_insert = true,       -- Start insert mode when entering terminal (default: true)
    start_insert = true,      -- Start insert mode when terminal starts (default: true)
    cleanup_renamed = true,   -- Cleanup buffers for renamed files (default: true)
    resize_key = "\x0c",      -- Key to send on resize (default: "\x0c" = Ctrl-L, "" to disable)

    -- Lf configuration
    lf_command = "map l open;map o ${{open $f}};set sortby name;set noreverse",

    -- Keybindings for opening files
    maps = {
      ["<C-t>"] = "tabedit",
      ["<C-s>"] = "split",
      ["<C-v>"] = "vsplit",
    },
  },
}
```

### Per-call Configuration

You can override defaults when calling `open()`:

```lua
require("snacks-lf").open({
  path = "/some/path",      -- Path to open in lf (default: current file or cwd)
  opener = "split",         -- Override default opener mode
  width = 0.9,              -- Override window width
  -- ... other options
})
```

### Configuration Examples

#### Use a bottom split instead of floating window

```lua
opts = {
  position = "bottom",
  height = 0.4,
}
```

#### Custom keybindings

```lua
opts = {
  maps = {
    ["<C-x>"] = "split",
    ["<C-y>"] = "vsplit",
    ["<C-n>"] = "tabedit",
  },
}
```

#### Custom lf configuration

```lua
opts = {
  lf_command = "set hidden;set preview;map l open",
}
```

#### Disable auto-insert mode

```lua
opts = {
  auto_insert = false,
  start_insert = false,
}
```

#### Customize auto-resize key

```lua
opts = {
  resize_key = "R",  -- Send 'R' key on resize (if you have it mapped to recol in lfrc)
  -- or
  resize_key = "",   -- Disable auto-resize completely
}
```

## API

### `require("snacks-lf").setup(opts)`

Setup function called by lazy.nvim to configure default options.

**Parameters:**
- `opts` (snacks-lf.Config, optional): Default configuration options

### `require("snacks-lf").open(opts)`

Opens lf file manager in a terminal.

**Parameters:**
- `opts` (snacks-lf.Config, optional): Configuration options (merged with defaults from setup)

**Returns:**
- Terminal instance from snacks.nvim

**Available Options:**
- `path` - Path to open in lf
- `width`, `height` - Window dimensions
- `title` - Window title
- `position` - Terminal position ("float", "bottom", etc.)
- `opener` - Default open mode ("edit", "split", etc.)
- `auto_insert`, `start_insert` - Insert mode behavior
- `lf_command` - Custom lf configuration
- `maps` - Keybindings for open modes
- `cleanup_renamed` - Whether to cleanup renamed file buffers
- `resize_key` - Key to send on terminal resize (default: "\x0c" = Ctrl-L, empty to disable)
- `env` - Environment variables to pass to terminal (TERM auto-added)

### `require("snacks-lf").toggle(opts)`

Toggles lf file manager (alias for `open()`).

**Parameters:**
- `opts` (snacks-lf.Config, optional): Configuration options

**Returns:**
- Terminal instance from snacks.nvim

## How it works

1. Opens lf with `-selection-path` to capture file selections
2. Monitors terminal keybindings to track opener mode
3. On lf exit (TermClose), reads selected files from temp file
4. Opens files according to the selected opener mode
5. Cleans up temp files and closes terminal

## Credits

- Inspired by [vim-floaterm](https://github.com/voldikss/vim-floaterm) lf integration
- Built on top of [snacks.nvim](https://github.com/folke/snacks.nvim)
- Uses [lf](https://github.com/gokcehan/lf) file manager

## License

MIT
