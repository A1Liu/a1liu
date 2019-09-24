Set-ExecutionPolicy RemoteSigned

Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install git -params '"/GitAndUnixToolsOnPath"'
choco install ripgrep fd


# New-Item -ItemType SymbolicLink -Path ".\.gitconfig" -Target ".\code\config\programs\neovim"
# New-Item -ItemType SymbolicLink -Path ".\AppData\Local\nvim" -Target ".\code\config\programs\neovim"

