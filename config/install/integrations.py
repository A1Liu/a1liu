#!/usr/bin/env python3
import os, sys
from pathlib import Path
install_dir = os.path.dirname(os.path.realpath(__file__))
project_dir = os.path.dirname(install_dir)
sys.path.insert(0, os.path.join(project_dir, 'programs'))
from aliu import config

should_undo = len(sys.argv) == 2 and sys.argv[1] == '--undo'
if config.already_installed("integrations") != should_undo:
    print("Nothing to do.")
    exit(0)

config.debug(f"Config directory is:         {config.project_dir}")
config.debug(f"Installation directory is:   {config.install_dir}")
config.debug(f"Machine-local directory is:  {config.local_dir}")
config.debug(f"Preconfig directory is:      {config.move_dir}")

if should_undo:
    config.remove_replace("~/.tmux.conf")
    config.remove_replace("~/.gitconfig")
    config.remove_replace("~/.gitignore_global")

    os.remove(config.install_flag_filename("integrations"))
    print("Integration configs uninstalled.")
    exit(0)

config.add_safe("~/.tmux.conf", "programs/tmux.conf")
config.add_safe("~/.gitconfig", "programs/gitconfig")
config.add_safe("~/.gitignore_global", "programs/gitignore_global")

open(config.install_flag_filename("integrations"), 'w').close()
print("Installed successfully.")
