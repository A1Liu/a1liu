#!/usr/bin/env python3
import os, sys
undo_dir = os.path.dirname(os.path.realpath(__file__))
install_dir = os.path.dirname(undo_dir)
project_dir = os.path.dirname(install_dir)
sys.path.insert(0, os.path.join(project_dir, 'programs'))
from aliu import config

if not config.already_installed("integrations"):
    print("Shell config not installed.")
    exit(0)

os.remove(config.install_flag_filename("integrations"))

config.debug(f"Config directory is:         {config.project_dir}")
config.debug(f"Installation directory is:   {config.install_dir}")
config.debug(f"Machine-local directory is:  {config.local_dir}")
config.debug(f"Preconfig directory is:      {config.move_dir}")

config.remove_replace("~/.tmux.conf")
config.remove_replace("~/.gitconfig")
config.remove_replace("~/.gitignore_global")
