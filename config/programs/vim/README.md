# Cheatsheet

## Visual
- `*`/`#` in visual mode - search for the text under your cursor

## Normal Mode
- `gx` - go to URL under cursor
- `<leader>b` in normal - go to def
- `<C-B>` in normal - show this file in NERDTree
- `<leader>f` in normal - search for text
- `<leader>o` in normal - search for path
- `<C-G>` in normal - Open this in github
- `<leader>g` in normal - show commit for line

## NERDTree
- `R` - refresh
- `C` - Change the folder under the cursor to be the new root

## Ignoring Files
- For ripgrep: `.rgignore` file

## Flags
All flags are prefixed by the string `vim-`.

#### Plugin Flags
Plugin flags are prefixed by `plug-`, in addition to `vim-`. So the `base` plugin
would be the flag `vim-plug-base`. When interacting with them via the `PlugFlag`
system, you refer to it just using the value `base`.

- `base`
  - UNIX file commands
  - Readline support
- `files` - enables NERDTree
- `solarized` - solarized color theme
- `fzf`
  - Fuzzy filename search
  - Fuzzy text search (requires ripgrep)
- `format` - Automatic formatting with :Autoformat
- `lsc` - Language server support for e.g. auto-importing functions
- `polyglot` - improved syntax highlighting
- `snippets` - Snippets

#### Other Flags
- `light-mode` - enables light mode
- `aliu` - Using `<C-T>` to put in a timestamped signature

## Default Flag Configuration
This command will add the default list plugins that I enable:
```
touch config/local/flags/vim-aliu config/local/flags/vim-plug-base \
    config/local/flags/vim-plug-files config/local/flags/vim-plug-fzf \
    config/local/flags/vim-plug-format config/local/flags/vim-plug-lsc \
    config/local/flags/vim-plug-polyglot
```
