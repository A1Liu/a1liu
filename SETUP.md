# Installation Instructions
`bootstrap.sh` does the whole thing on a machine with nothing on it: nix, the
system-level nix config for the profile if it has one, then home-manager.

```sh
curl -fsSL https://raw.githubusercontent.com/A1Liu/a1liu/main/bootstrap.sh | sh -s -- vps
```

The profiles are `macos` and `vps`. Everything below is the same thing by hand.

On Linux and MacOS, you should start by installing Nix. Use Nix/Nix Darwin to
install system dependencies, including `home-manager`, and then use home manager
to install everything else:

```sh
home-manager switch --flake ./home-manager#aliu-linux
home-manager switch --flake ./home-manager#aliu-vps # headless server, as root
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

### MacOS
See [`nix/darwin/MacOS.md`](./nix/darwin/MacOS.md) for setup.

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
