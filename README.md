# Configurations
My configurations! This repo contains the things that I like to keep constant
between systems; things like application settings, file organizations, etc.

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
├── public ======= Next.js Assets folder
└── shells ------- Configurations used by shell sessions
```

### Installation Scripts
This repository includes multiple installation scripts for setting up a new computer,
or just trying out some of my configurations. For more information about installation,
please see `install/README.md`.

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
  - `light-mode` - Whether or not Vim is dark or light mode
  - `plugins-base-enabled` - Whether or not the default plugins are enabled
  - `plugins-eval-enabled` - Whether or not EvalSelection is enabled
  - `plugins-solarized-enabled` - Whether or not the color scheme plugin is enabled
  - `plugins-lsc-enabled` - Whether or not the language server client is enabled
  - `plugins-snippets-enabled` - Whether or not vim-snippets is enabled
  - `plugins-polyglot-enabled` - Whether or not vim-polyglot is enabled
