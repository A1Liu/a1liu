# Setup Scripts for New Devices
These scripts do basic setup for new devices. The first stage runs the bootstrap
script, which does the following:

1. Install Git
2. Clone this repository

Then, each of the scripts does the following:

1. Set up simple workflow
  - Soft-link config files for NeoVim/Vim, Git
  - Set defaults for text editor, terminal, and shell
2. Install applications
  - Chrome & FireFox
  - Alacritty
  - Zsh
  - NeoVim
3. Programming Languages
  - Python
  - Java
  - C/C++ (Clang)
  - Rust
  - Haskell
  - Ruby
  - Node.js
4. Convenience
  - rustfmt
  - Clang Format
  - Eclim
  - Prettier.js
  - Soft-link startup/on-login files

Depending on the tasks, some of the above functionality may be done through existing
scripts, found in the `reuse` folder.
