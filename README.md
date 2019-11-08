# Configurations
My configurations! This repo represents the things that I like to keep constant between systems; things like
application settings, file organizations, etc.

### Structure

```
.
├── local -------- Machine-specific configuration settings
│   ├── flags ==== Persistent flags for configuration, like whether a config has been run
│   └── preconf -- Files that my configurations replaced
├── install ====== Scripts to install this configuration on a new machine
│   └── undo ----- Scripts that undo their counterpart in `install`
├── programs ===== Configurations used by programs that I use
├── shells ------- Configurations used by shell sessions
├── compat ======= Configurations that need to be different for each OS
├── libs --------- Utility libraries that I've written over the years
└── startup ====== Scripts that are run at startup
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

### Installation Scripts
This repository includes multiple installation scripts for setting up a new computer.
For more information about installation, please see `install/README.md`. The
following scripts are usable:

- `shell` - Installs editor/Git configurations for a working shell. Install with

  ```sh
  . install/shell
  ```

- `elementaryos` - Installs useful programs for ElementaryOS, and also runs `shell`.

  ```sh
  . install/elementaryos
  ```

