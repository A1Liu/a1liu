# DEPRECATED
This is what I used before switching to NixOS/Nix. So far Nix has been able to
completely solve the problem of configuration management for me, so none of this
is relevant anymore.

# Configurations
My configurations! This repo contains the things that I like to keep constant
between systems; things like application settings, file organizations, etc.

### Installation Scripts
This repository uses `home-manager` to install configs.
For more information about installation, please see `install/README.md`.

### Structure

```
.
├── local -------- Machine-specific files
│   ├── flags ==== Persistent configuration flags, e.g. whether a config has been run
│   └── preconf -- Files that my configurations replaced
├── install ====== Scripts to install this configuration on a new machine
│   └── undo ----- Scripts that undo their counterpart in `install`
└── programs ===== Configurations used by programs that I use
```

### TODO
- `programs/vim/init.vim` -> should paths care about `/` vs `\`?
- `shell/env` -> WTF do we do about `/etc/zshenv` and whatnot?
- `install/?` -> M1 needs to handle HomeBrew `$PATH` properly, i.e. `usr/local/bin`
  and `opt/homebrew/bin` before `/bin` (or something like that, idk tbh)
- `install/?` -> needs to copy files instead of just moving them.
- `install/setup` -> reorganize, maybe just turn it into docs instead of scripts
- SSH key stuff

### Useful Windows/PowerShell Commands

- Delete all local branches

  ```ps1
  git for-each-ref --format '%(refname:short)' refs/heads | %{ $_.Trim() } | ?{ $_ -ne 'master' } | ?{ $_ -ne 'main'} | ?{ $_ -ne 'develop'} | %{ git branch -D $_ }
  ```
