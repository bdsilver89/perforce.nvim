# perforce.nvim

**perforce.nvim** is a Perforce plugin for Neovim.

## Features
- Provides signs in the signcolumn to show changed, added, and removed lines
- Endpoints to navigate and preview diff hunks
- Automatically open files for edit
- Diffing files

## Requirements
- Neovim >= **0.8.0**
- Perforce

## Installation
Install the plugin with your preferred package manager:

<!-- bootstrap:start -->
[lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
  "bdsilver89/perforce.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  event = "VeryLazy",
  opts = {}
}
```

[packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use {
    "bdsilver89/perforce.nvim",
    config = function()
        require("perforce").setup()
    end
}
```
<!-- bootstrap:end -->

## Configuration

*perforce.nvim* comes with the following defaults:

```lua
{
  -- Perforce executable name
  executable = "p4", ---@type string

  -- Set to false to disable prompts to open a file for editing
  -- Or toggle with :P4 toggle_open_on_change
  open_on_change = true, ---@type boolean

  -- Set to false to disable highlights in the signcolumn
  -- Or toggle with :P4 toggle_signs
  signcolumn = true, ---@type boolean

  -- Set to true to enable highlights in the numbercolumn
  -- Or toggle with :P4 toggle_numhl
  numhl = false, ---@type boolean

  -- Set to true to enable line highlights
  -- Or toggle with :P4 toggle_linehl
  linehl = false, ---@type boolean

  -- Set to true to enable word diff
  -- Or toggle with :P4 toggle_word_diff
  word_diff = false, ---@type boolean

  show_deleted = false, ---@type boolean
  sign_priority = 6, ---@type integer
  extmark_signs = false, ---@type boolean
  refresh_on_update = false, ---@type boolean

  ---@type Perforce.DiffOpts
  diff_opts = {
    algorithm = "myers",
    internal = true,
    indent_heuristic = false,
    vertical = true,
    linematch = nil,
  },

  -- If you are not using a Nerd font, replace the symbols with a compatible text character
  ---@type table<Perforce.SignType, Perforce.SignConfig>
  signs = {
    add = {
      hl = "PerforceAdd",
      text = "┃",
      numhl = "PerforceAddNr",
      linehl = "PerforceAddLn"
    },
    change = {
      hl = "PerforceChange",
      text = "┃",
      numhl = "PerforceChangeNr",
      linehl = "PerforceChangeLn",
    },
    delete = {
      hl = "PerforceDelete",
      text = "▁",
      numhl = "PerforceDeleteNr",
      linehl = "PerforceDeleteLn",
    },
    topdelete = {
      hl = "PerforceTopdelete",
      text = "▔",
      numhl = "PerforceTopdeleteNr",
      linehl = "PerforceTopdeleteLn",
    },
    changedelete = {
      hl = "PerforceChangedelete",
      text = "~",
      numhl = "PerforceChangedeleteNr",
      linehl = "PerforceChangedeleteLn",
    },
    untracked = {
      hl = "PerforceUntracked",
      text = "┆",
      numhl = "PerforceUntrackedNr",
      linehl = "PerforceUntrackedLn",
    },
  },

  ---@type table<string|interger, string>
  count_chars = {
    [1] = "1",
    [2] = "2",
    [3] = "3",
    [4] = "4",
    [5] = "5",
    [6] = "6",
    [7] = "7",
    [8] = "8",
    [9] = "9",
    ["+"] = ">",
  },

  ---@type table<string, any>
  preview_config = {
    border = "single",
    style = "minimal",
    relative = "cursor",
    row = 0,
    col = 1,
  },

  watch_dir = {
    enable = false, ---@type boolean
  },
}
```

## Commands
TBD

## API
TBD
