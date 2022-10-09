# Install Scripts
All of these scripts should be run locally by cloning the repository first.

## Available Scripts
The following scripts are usable:

- `shell.py` - Installs shell configurations for a working shell.
- `vim.py` - Installs Vim configurations.
- `integrations.py` installs Git and Tmux configurations.
- `setup/S` - Installs useful programs for an operating system called `S`

## Installation Instructions
The instructions below supplement the installation scripts in this directory, and
hopefully make the process easier.

### Shell
This script depends on Python 3 being installed.

1. Clone repository with `git clone https://github.com/A1Liu/config.git`
2. Install environment using `python3 install/shell.py`. Replaced files will be
   stored in `local/preconf`, under their original name.
3. Some stuff doesn't work unless you use these commands from the project root:

   ```
   tic -x config/programs/tmux-256color.terminfo
   tic -x config/programs/xterm-256color-italic.terminfo
   ```

   Not sure what they do. They also don't always work.

To undo, run `python3 install/undo/shell.py`. It'll reset your configuration to
before the install script was run. Note that this requires the appropriate files
to have been saved in `local/preconf`.

###  Vim
This script depends on Python 3 being installed.

1. Clone repository with `git clone https://github.com/A1Liu/config.git`
2. Install environment using `python3 install/vim.py`. Replaced files will be
   stored in `local/preconf`, under their original name.

To undo, run `python3 install/undo/vim.py`. It'll reset your configuration to
before the install script was run. Note that this requires the appropriate files
to have been saved in `local/preconf`.

### MacOS
See `MacOS.md`.

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
