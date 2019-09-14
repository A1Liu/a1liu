# Configurations
My configurations! This repo represents the things that I like to keep constant between systems; things like
application settings, file organizations, etc.

### Structure

```
.
├── local -------- Machine-specific configuration settings
│   └── preconf -- Files that my configurations replaced
├── install ------ Scripts to install this configuration on a new machine
│   └── undo ----- Scripts that undo their counterpart in `install`
├── neovim ------- Vim configuration settings
├── shells ------- Configurations used by shell sessions
├── programs ----- Configurations used by programs that I use
└── startup ------ Scripts that are run at startup
```

### Semantically Meaningful Environment Variables

- `CFG_DIR` - Configuration directory (this repository)
- `IS_INTERACTIVE_SHELL` - Whether or not the shell is interactive
- `CFG_SHELL_ENV` - Guard variable for checking if path is correctly set
- `CFG_ENV` - Guard variable for checking if environment variables are set

### Installation Scripts
The following scripts are usable:

- `shell` - Installs editor configurations for a working shell. Install with

  ```
  sh install/shell
  ```



