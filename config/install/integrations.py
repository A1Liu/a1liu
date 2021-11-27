#!/usr/bin/env python3
import os, sys
from pathlib import Path
install_dir = os.path.dirname(os.path.realpath(__file__))
project_dir = os.path.dirname(install_dir)
sys.path.insert(0, os.path.join(project_dir, 'programs'))
from aliu import config

if config.already_installed("integrations"):
    print("Already installed.")
    exit(0)

config.add_safe("~/.tmux.conf", "programs/tmux.conf")
config.add_safe("~/.gitconfig", "programs/gitconfig")
config.add_safe("~/.gitignore_global", "programs/gitignore_global")

open(config.install_flag_filename("integrations"), 'w').close()
print("Installed successfully.")
