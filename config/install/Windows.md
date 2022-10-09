# Un-Fucking Windows Guide
The core tenet of Microsoft has and will always be to insert as much Microsoft
Bullshit as they can into your computer until the government files an anti-trust
lawsuit to stop them. Most of the process of un-fucking Windows is simply deleting
things that are installed by default, like:

1. Instagram
2. WhatsApp
3. Facebook Messenger
4. Microsoft Teams

There's also a number of "widgets" that Microsoft integrates directly into the
user interface through the task bar, and the only way to fully remove things like
the news widget is to disable the task bar completely, so do that as well.

## Actual Setup
There are a few things that are useful to do in addition to removing
as much bloatware and spyware as Microsoft will allow you to:

1. Enable developer mode and associated features (Settings -&gt; Updates &amp; Security
   -&gt; For Developers)

2. Install Chocolatey and Git (in PowerShell with admin privileges):

   ```
   Set-ExecutionPolicy Unrestricted
   iex ((New-Object System.Net.WebClient).DownloadString("https://chocolatey.org/install.ps1"))
   choco install git.install --params "/GitAndUnixToolsOnPath /WindowsTerminal" -y
   ```

2. Add ssh stuff with `ssh-keygen`

3. Clone the repository using `git clone git@github.com:A1Liu/config`

4. [Install Vim](https://github.com/vim/vim-win32-installer/releases). Make sure
   it's the 64-bit version.

5. [Download SharpKeys](https://www.randyrants.com/category/sharpkeys/) and load
   the settings stored in this repository under `compat\windows\keybindings.skl`

6. Install Python 3.8 using the [Python 3.8 installer](https://www.python.org/downloads/release/python-382/),
   and customize the install by ensuring that it's installed for all users, adding
   python to the environment variables, and not precompiling the standard library.

7. Windows is broken, so follow this to get debugging native files to work:
   https://docs.microsoft.com/en-us/visualstudio/debugger/debug-using-the-just-in-time-debugger?view=vs-2019#jit_errors

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
