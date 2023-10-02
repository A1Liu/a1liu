# Configurations
My configurations! This repo contains the things that I like to keep constant
between systems; things like application settings, file organizations, etc.

### Installation Scripts
This repository includes multiple installation scripts for setting up a new computer,
or just trying out some of my configurations. For more information about installation,
please see `install/README.md`.

### Structure

```
.
├── local -------- Machine-specific files
│   ├── flags ==== Persistent configuration flags, e.g. whether a config has been run
│   └── preconf -- Files that my configurations replaced
├── install ====== Scripts to install this configuration on a new machine
│   └── undo ----- Scripts that undo their counterpart in `install`
├── programs ===== Configurations used by programs that I use
├── pages -------- Next.js routes
└── shells ======= Configurations used by shell sessions
```

### Environment Variables

- `CFG_DIR` - Configuration directory (this repository)
- `IS_INTERACTIVE_SHELL` - Whether or not the shell is interactive
- `CFG_SHELL_ENV` - Guard variable for checking if path is correctly set
- `CFG_ENV` - Guard variable for checking if environment variables are set

##### Install Scripts
The install scripts respect these environment variables when installing:

- `DEBUG` - Output debug information
- `DRY_RUN` - Don't actually affect the outside environment

##### Vim
My Vim config uses these environment variables at startup:

- `VIM_DEBUG` - Debug flag for vim

### Flag Files
- `installed-S` - Whether or not `S` has been run, where `S` is a Python script
  in the install folder (e.g. `shell.py` is represented with `installed-shell`).
- `vim-S` A Vim flag, where `S` is the name of the flag
  - `plug-base`
    - UNIX file commands
    - Readline support
  - `plug-files` - enables NERDTree
  - `plug-solarized` - solarized color theme
  - `plug-fzf`
    - Fuzzy filename search
    - Fuzzy text search (requires ripgrep)
  - `aliu` - Using `<C-T>` to put in a timestamped signature
  - `plug-format` - Automatic formatting with :Autoformat
  - `plug-lsc` - Language server support for e.g. auto-importing functions
  - `plug-polyglot` - improved syntax highlighting
  - `light-mode` - enables light mode
  - `plug-snippets` - Snippets

### TODO
- `programs/vim/init.vim` -> should paths care about `/` vs `\`?
- `shell/env` -> WTF do we do about `/etc/zshenv` and whatnot?
- `install/?` -> M1 needs to handle HomeBrew `$PATH` properly, i.e. `usr/local/bin`
  and `opt/homebrew/bin` before `/bin` (or something like that, idk tbh)
- `install/?` -> needs to copy files instead of just moving them.
- `install/setup` -> reorganize, maybe just turn it into docs instead of scripts
- SSH key stuff
- Figure out how to handle new Zig dependency for path management stuffs
