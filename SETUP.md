# Installation Instructions
The instructions below supplement the installation scripts in this directory, and
hopefully make the process easier.

On Linux and MacOS, you should start by installing Nix. Use Nix/Nix Darwin to
install system dependencies, including `home-manager`, and then use home manager
to install everything else:

```sh
home-manager switch --flake ./home-manager#aliu-linux
```

### Directory Structure

```
.
├── home-manager --- Responsible for configuring most programs
├── nix ============ Information on setting up various operating systems
├── shell ---------- Configurations for shells; includes nix-shell files
├── src ============ Svelte code
├── static --------- Svelte static files
└── vim ============ Vim/Neovim configuration code
```

## System Setup

### NixOS
1. Use `nix/nixos/configuration.nix` by symlinking it into `/etc/nixos`:

   ```sh
   sudo ln -s $PWD/nix/nixos/configuration.nix /etc/nixos/configuration.nix
   ```

1. Run the following, which rebuilds the system with the new configuration:

   ```sh
   sudo nixos-rebuild switch
   ```

### Linux

### MacOS
Install [nix-darwin](https://github.com/LnL7/nix-darwin) and run

```sh
darwin-rebuild switch --flake ./nix/darwin#aliu
```

See [`nix/darwin/MacOS.md`](./nix/darwin/MacOS.md) for more.

### Windows
See `Windows.md`.

### ElementaryOS
1. Install Git using `sudo apt-get install git`
2. Clone repository with `git clone https://github.com/A1Liu/config.git`
2. Install software using `. setup/elementaryos` (this will require admin access)
3. Install keybindings by going into `settings -> keyboard -> layout`
4. Set up ssh stuff with `ssh-keygen`
5. Remove bell sounds with `sudo vi /etc/inputrc`, uncommenting the line `set bell-style none`
6. Potentially diagnose and fix problems with graphics card not waking up after
   suspend
   -  https://www.reddit.com/r/elementaryos/comments/3akt9g/black_screen_after_wake_up_from_suspend/
   -  https://www.reddit.com/r/elementaryos/comments/382e76/how_to_fix_cannot_wake_up_from_suspend_issue/
7. [Set up virtual console](https://askubuntu.com/questions/982863/change-caps-lock-to-control-in-virtual-console-on-ubuntu-17)
