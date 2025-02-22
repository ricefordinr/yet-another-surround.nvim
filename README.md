# Neovim Surround Plugin

Another simple Neovim plugin for surrounding text with pairs of characters. Works in visual mode and handles both single and multi-line selections.

## Features

- Surround text with matching pairs (`()`, `[]`, `{}`, `""`, `''`, `<>`, ` `` `, `||`)
- Add surrounds with or without spaces
- Remove existing surrounds using space as the trigger
- Works with both single and multi-line selections
- Smart detection of existing surrounds (both within and outside selection)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "ricefordinr/yet-another-surround.nvim",
    config = function()
        require("surround").setup()
    end
}
```

## Usage

1. Select text in visual mode
2. Use one of the following commands:
   - `<leader>s` to surround without spaces
   - `<leader>S` to surround with spaces
3. Press the character you want to surround with

To remove surrounds:

1. Select the text (with or without the surrounding characters)
2. Press `<leader>s` or `<leader>S`
3. Press space

## Configuration

You can customize the keymaps during setup:

```lua
require("surround").setup({
    surround_no_space = "<leader>s",  -- Default keymap for surround without spaces
    surround_with_space = "<leader>S" -- Default keymap for surround with spaces
})
```

## Supported Pairs

- Parentheses: `()`
- Brackets: `[]`
- Braces: `{}`
- Angle brackets: `<>`
- Single quotes: `''`
- Double quotes: `""`
- Backticks: ` `` `
- Pipes: `||`

The plugin will automatically use the matching pair when either character is pressed. For example, pressing `)` will use `()` as the surround pair.
