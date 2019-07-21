# Configurations
My configurations! This repo represents the things that I like to keep constant between systems; things like
application settings, file organizations, etc.

### Structure

```
.
├── install ---- Scripts to install this configuration on a new machine
    └── undo --- Scripts that undo their counterpart in `install`
├── neovim ----- Vim configuration settings
├── shell ------ Configurations used by shell sessions
└── startup ---- Scripts that are run at startup
```

### TODO
* [ ] Better method of checking for configuration than `-e ~/.aliu_config_installed`
* [ ] Check for pre-existing files, stuff like that
* [ ] Scripts to move stuff around w/ symbolic links
* [ ] More cross-platform compatibility
* [x] Zsh settings

### Installation Scripts
The following scripts are usable:

- `bootstrap` - Installs the repository, checking whether or not you've already
  installed it. Install with

  ```
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/A1Liu/config/master/install/bootstrap)"
  ```

  This script must be installed before all others.

- `shell` - Installs editor configurations for a working shell. Install with

  ```
  sh install/shell
  ```

  in the root of the repository.



