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

### Installation Scripts
The following scripts are usable:

- `bootstrap` - Installs the repository to the current directory. Install with

  ```
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/A1Liu/config/master/install/bootstrap)"
  ```

  This script must be installed before all others.

- `shell` - Installs editor configurations for a working shell. Install with

  ```
  sh install/shell
  ```


