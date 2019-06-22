# Setup Scripts for New Devices
These scripts do basic setup for new devices. The first stage runs the bootstrap
script, which does the following:

1. Install Git
2. Clone this repository

Then, each of the scripts does the following:

1. Set up basic workflow
  - Chrome & FireFox
  - Alacritty
  - Zsh
  - NeoVim
  - Python
  - Java
  - Soft-link config files for alacritty, NeoVim, Git
  - Set defaults for text editor, terminal, and shell
2. Convenience
  - Clang Format
  - Eclim
  - Conky
  - GCalClI
  - Soft-link startup/on-login files
3. Programming Languages
  - GCC & Clang
  - Rust
  - Haskell
  - Ruby
  - Node.js

Depending on the tasks, some of the above functionality may be done through existing
scripts, found in the `reuse` folder.
