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
user interface through the task bar; these can't really be removed from the OS
officially, but can be disabled entirely by running this command in PowerShell
as administrator:

```
winget uninstall "windows web experience pack"
```

### Starting off Right: Using "English International"
When creating the Windows ISO, you should use the "English International" option,
instead of English. This means that you'll get an EU regulation compliant version
of Windows, which will make it much easier to uninstall everything. It also will
not contain copilot (as of 2024). For more info, see [this article](https://www.zdnet.com/article/heres-how-microsoft-will-change-windows-to-comply-with-eu-laws/)

NOTE: I have not been able to get this to work properly yet. However, in theory
it should make the experience better.

### Use Rufus to Bypass internet connectivity requirements
Another thing you can do to reduce the amount of nonsense installed without you even
knowing is to remove the requirement to install Windows with an internet connection.
See [rufus](https://rufus.ie/en/) which does this for you during the ISO burn step.

### Adding a `bin` folder
Copied from: https://www.reddit.com/r/commandline/comments/7r574s/comment/dsv1z5u/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button

These steps need to be done once per account only
- Add the `/bin` folder at the root of your user (`%USERPROFILE%/bin`)
- Run `control sysdm.cpl`, in the tab "Advanced" click on "Environment Variables..."
  and add `%USERPROFILE%\bin` to the PATH variable of your account, don't edit the
  global `PATH` variable. It's your decision if you want it at the start or at the end.
  Windows goes through this in order and will stop as soon as a match is found.

### Removing Web Results/Bing from Windows Search
Following [this article](https://nerdschalk.com/how-to-disable-web-results-in-windows-11-start-or-search-menu/):

Make a DWORD at Computer\HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Explorer\DisableSearchBoxSuggestions and set it to 1.

### Removing Microsoft Teams
Following [this reddit comment](https://www.reddit.com/r/sysadmin/comments/q771i4/comment/ho15fvm/?utm_source=share&utm_medium=web2x&context=3):

> After a long running ticket with Microsoft, they sent us a registry key to set which resolves this problem.
>
> Make a DWORD at HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications\ConfigureChatAutoInstall and set to 0
>
> We use this in tandem with the DWORD at HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Chat\ChatIcon set to 3, which disables the chat icon and chat settings slider for all users.

### Turning off Windows Update
To turn it off, following [this guide](https://www.minitool.com/data-recovery/how-to-stop-windows-11-update.html):

1. Press Windows + R, type services.msc in Run dialog, and press Enter to open Windows Services.
2. Scroll down in the services list and find Windows Update service. Double-click Windows Update service to open its properties window.
3. Under General tab, next to Startup type option, you can click the drop-down icon to select Disabled option.
4. Click Apply and click OK to apply the changes. In this way, it will permanently disable Windows 11 automatic updates.


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

4. [Install Clink](https://chrisant996.github.io/clink/).

4. [Install Vim](https://github.com/vim/vim-win32-installer/releases). Make sure
   it's the 64-bit version.

5. [Download SharpKeys](https://apps.microsoft.com/store/detail/XPFFCG7M673D4F) and load
   the settings stored in this repository under `compat\windows\keybindings.skl`

6. Install Python 3.8 using the [Python 3.8 installer](https://www.python.org/downloads/release/python-382/),
   and customize the install by ensuring that it's installed for all users, adding
   python to the environment variables, and not precompiling the standard library.

7. Windows is broken, so follow this to get debugging native files to work:
   https://docs.microsoft.com/en-us/visualstudio/debugger/debug-using-the-just-in-time-debugger?view=vs-2019#jit_errors

8. Install [NVM for Windows, version 1.1.12](https://github.com/coreybutler/nvm-windows/releases/tag/1.1.12), and make
   sure to install Node version `20.17.0` (or at least, that version has a working version of `npm`, and I have not tested any other version combinations recently).

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
