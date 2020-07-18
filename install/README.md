# Install Scripts
All of these scripts should be run locally by cloning the repository first.

## Available Scripts
The following scripts are usable:

- `shell.py` - Installs editor/shell configurations for a working shell.
- `integrations.py` installs Git and Tmux configurations.
- `elementaryos` - Installs useful programs for ElementaryOS.
- `mac` - Installs useful programs for MacOS.
- `windows.ps1` - Sets up programs like Vim and Windows Terminal to work properly.

## Installation Instructions
The instructions below supplement the installation scripts in this directory, and
hopefully make the process easier.

### Shell
This script depends on Python 3 being installed.

1. Clone repository with `git clone https://github.com/A1Liu/config.git`
2. Install environment using `python3 install/shell.py`. Replaced files will be
2  stored in `local/preconf`, under their original name.

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
1. Enable developer mode and associated features (Settings -&gt; Updates &amp; Security
   -&gt; For Developers)

2. Install Chocolatey and Git:

   ```
   iex ((New-Object System.Net.WebClient).DownloadString("https://chocolatey.org/install.ps1"))
   choco install git.install --params "/GitAndUnixToolsOnPath /WindowsTerminal" -y
   ```

3. Clone the repository using `git clone https://github.com/a1liu/config`

4. [Install Vim](https://github.com/vim/vim-win32-installer/releases). Make sure
   it's the 64-bit version.

5. [Download SharpKeys](https://www.randyrants.com/category/sharpkeys/) and load
   the settings stored in this repository under `compat/windows/keybindings.skl`

6. Run setup script `windows.ps1`.

7. Install Python 3.8 using the [Python 3.8 installer](https://www.python.org/downloads/release/python-382/),
   and customize the install by ensuring that it's installed for all users, adding
   python to the environment variables, and not precompiling the standard library.

### Windows Subsystem for Linux
1. Install Windows Subsystem for Linux

   ```
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
   ```

   And then restart your computer.

2. Install a distribution of Linux, then open it, right click on the window bar,
   and select properties. Then enable "Use Ctrl+Shift+C/V as Copy/Paste"

3. Enable copy-paste functionality in Vim using
   [VcXsrv](https://sourceforge.net/projects/vcxsrv/) with its default configurations,
   then save those configurations to `$HOME\AppData\Roaming\Microsoft\Windows\Startup`
