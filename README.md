# Neovim Surround Plugin

Well... another surround plugin. But hey, this one is different! (Sort of.)

## What makes this different?

- Introducing Surround Mode: Instead of doing everything at once, you can continuously insert or delete surrounds until you press ESC.
- No need to remember weird commands or keybindings, just select text, activate Surround Mode, and spam keys like a true gamer.

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

## Demo

Not yet

## Usage

### It's very human to use!!

1. Select some text in visual mode.
2. Press "<leader>s" (or your configured keybinding).
3. Smash the (, {, ", or any other surround key you desire.
4. Press Backspace to remove the last added surround.
5. Hit Esc to finalize and go back to your normal life.

### Supported Pairs

- Parentheses: `()`
- Brackets: `[]`
- Braces: `{}`
- Angle brackets: `<>`
- Single quotes: `''`
- Double quotes: `""`
- Backticks: ` `` `
- Pipes: `||`

The plugin will automatically use the matching pair when either character is pressed. For example, pressing `)` will use `()` as the surround pair.

## Bug(s)

- **Selecting a character at the end of a line?** Yeah... that breaks it. **Why?** Because I'm bad. (I'll fix it eventually.)

## Configuration

Want to change the keybinding? You can do that!

```lua
require("surround").setup({
    surround_mode_key = "<leader>s",  -- Default
})
```

## Why does this exist?

Yes
