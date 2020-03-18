# Install Scripts
All of these scripts should be run locally by cloning the repository first.

## Available Scripts
The following scripts are usable:

- `shell.py` - Installs editor/shell configurations for a working shell. Install with

  ```sh
  python3 install/shell.py
  ```

- `integrations.py` installs Git and Tmux configurations. Install with

  ```sh
  python3 install/integrations.py
  ```

- `elementaryos` - Installs useful programs for ElementaryOS, and also runs `shell`.
  Install with

  ```sh
  . install/elementaryos
  ```

## Installation Instructions
The instructions below supplement the installation scripts in this directory, and
hopefully make the process easier.

### Shell
1. Install Python 3.
2. Clone repository with `git clone https://github.com/A1Liu/config.git`
3. Install environment using `python3 install/shell.py`. Replaced files will be
   stored in `local/preconf`, under their original name. If for some godforsaken
   reason there are multiple versions of the same file, they will be renamed in
   turn with a prefixed underscore.

To undo, run `python3 install/undo/shell.py`. It'll reset your configuration to
before the install script was run. Note that this requires the appropriate files
to have been saved in `local/preconf`.

### MacOS
1. Install XCode tools using `xcode-select --install`
2. Clone repository with `git clone https://github.com/A1Liu/config.git`
3. Install software using `. install/mac` (this will require admin access)
4. Remove annoying Terminal stuff:
   1. Preferences > Profiles > Shell > When Shell Exits
   1. Preferences > Profiles > Advanced > Bell > Audible bell
5. Remap Caps Lock to control: System Preferences > Keyboard > Keyboard > Modifier Keys
6. 

### ElementaryOS
1. Install Git using `sudo apt-get install git`
2. Clone repository with `git clone https://github.com/A1Liu/config.git`
2. Install software using `. install/elementaryos` (this will require admin access)
3. Install keybindings by going into `settings -> keyboard -> layout`
4. Set up ssh stuff with `ssh-keygen`
5. Remove bell sounds with `sudo vi /etc/inputrc`, uncommenting the line `set bell-style none`
6. Potentially diagnose and fix problems with graphics card not waking up after
   suspend
   -  https://www.reddit.com/r/elementaryos/comments/3akt9g/black_screen_after_wake_up_from_suspend/
   -  https://www.reddit.com/r/elementaryos/comments/382e76/how_to_fix_cannot_wake_up_from_suspend_issue/
7. [Set up virtual console](https://askubuntu.com/questions/982863/change-caps-lock-to-control-in-virtual-console-on-ubuntu-17)

### Windows
1. Enable developer mode and associated features (Settings -> Updates &amp; Security -> For Developers)
2. Install Chocolatey using:

   ```
   iex ((New-Object System.Net.WebClient).DownloadString("https://chocolatey.org/install.ps1"))
   ```

3. Install Git using:

   ```
   choco install git.install --params "/GitAndUnixToolsOnPath /WindowsTerminal" -y
   ```

4. Clone the repository using `git clone https://github.com/a1liu/config`

5. [Download SharpKeys](https://www.randyrants.com/category/sharpkeys/) and load
   the settings stored in this repository under `compat/windows/keybindings.skl`

6. [Install Vim](https://www.vim.org/download.php)

7. Link files using `mklink` in Command Prompt:

   1. `mklink /d ~/vimfiles config/programs/neovim`
   2. `mklink ~/.vimrc config/programs/neovim/init.vim`

### Windows Subsystem for Linux
1. Install Windows Subsystem for Linux

   ```
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
   ```

2. Install a distribution of Linux, then open it, right click on the window bar,
   and select properties. Then enable "Use Ctrl+Shift+C/V as Copy/Paste"

3. Enable copy-paste functionality in Vim using https://github.com/Microsoft/WSL/issues/892#issuecomment-275873108
