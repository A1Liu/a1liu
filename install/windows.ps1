# Set-ExecutionPolicy AllSigned


$installDir = [System.IO.Path]::GetDirectoryName($PSCommandPath)
$configDir = [System.IO.Path]::GetDirectoryName($installDir)

choco install ripgrep fd firefox -y

# New-Item -ItemType SymbolicLink -Path ".\.gitconfig" -Target ".\code\config\programs\neovim"
# New-Item -ItemType SymbolicLink -Path ".\AppData\Local\nvim" -Target ".\code\config\programs\neovim"

# Set up command prompt init file
New-ItemProperty -Path "HKCU\Software\Microsoft\Command Processor" -Name 'AutoRun' -Value "$configDir\shells\command-prompt.cmd" -PropertyType DWORD

# Install Windows Subsystem for Linux
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

# Install Ubuntu
# Invoke-RestMethod -Uri "https://aka.ms/wsl-debian-gnulinux" -OutFile "~/Ubuntu.zip" -UseBasicParsing

# Setting up Vim
# $(get-item "$HOME\.vimrc").Delete()
# $(get-item "$HOME\vimfiles").Delete()
# New-Item -ItemType SymbolicLink -Path "$HOME\.vimrc" -Target "$configDir\programs\neovim\init.vim"
# New-Item -ItemType SymbolicLink -Path "$HOME\vimfiles" -Target "$configDir\programs\neovim"

# Making Windows Terminal behave correctly
# TODO Fix this by using the same features that every other script uses
# $(get-item "$env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState").Delete()
# New-Item -ItemType SymbolicLink -Path "$env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState" -Target "$configDir\programs\windows-terminal"

# Get VcXsrc to start alongside Windows
# New-Item -ItemType SymbolicLink -Path "$HOME\AppData\Roaming\Microsoft\Windows\"

