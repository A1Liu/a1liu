# Configurations
My configurations! This repo contains the things that I like to keep constant
between systems; things like application settings, file organizations, etc.

### Structure

```
.
├── local -------- Machine-specific configuration settings
│   ├── flags ==== Persistent configuration flags, e.g. whether a config has been run
│   └── preconf -- Files that my configurations replaced
├── install ====== Scripts to install this configuration on a new machine
│   └── undo ----- Scripts that undo their counterpart in `install`
├── programs ===== Configurations used by programs that I use
├── shells ------- Configurations used by shell sessions
├── compat ======= Configurations that need to be different for each OS
└── libs --------- Utility libraries that I've written over the years
```

### Semantically Meaningful Environment Variables

- `CFG_DIR` - Configuration directory (this repository)
- `IS_INTERACTIVE_SHELL` - Whether or not the shell is interactive
- `CFG_SHELL_ENV` - Guard variable for checking if path is correctly set
- `CFG_ENV` - Guard variable for checking if environment variables are set

##### Install Scripts
- `DEBUG` - Output debug information
- `DRY_RUN` - Don't actually affect the outside environment

##### Vim
- `VIM_DEBUG` - Debug flag for vim

### Flag Files
- `installed-S` - Whether or not `S` has been run, where `S` is a script in the
  install folder.
- `vim-light-mode` - Whether or not Vim is dark or light mode
- `vim-plugins-installed` - Whether or not plugins are installed; managed by scripts
- `vim-plugins-enabled` - Whether or not plugins are enabled
- `vim-lang-server-enabled` - Whether or not the lang server is enabled

### Installation Scripts
This repository includes multiple installation scripts for setting up a new computer,
or just trying out some of my configurations. For more information about installation,
please see `install/README.md`.
