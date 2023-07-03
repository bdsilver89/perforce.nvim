# perforce.nvim

**perforce.nvim** is a perforce plugin for Neovim.

## Features
TBD

## Requirements
- Neovim >= **0.8.0**
- Perforce

## Installation

Install the plugin with your preferred package manager:

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

## Configuration

**perforce.nvim** comes with the following defaults:

```lua
{

}
```

## Perforce Options

| **Property** | **Type** | **Description** |
| ------------ | -------- | --------------- |

## Commands
TBD

## API
TBD


