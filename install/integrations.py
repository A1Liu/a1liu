#!/usr/bin/env python3
import os, sys
from pathlib import Path
install_dir = os.path.dirname(os.path.realpath(__file__))
project_dir = os.path.dirname(install_dir)
sys.path.insert(0, os.path.join(project_dir, 'libs', 'python'))
from aliu import files
from aliu import config
from aliu.logging import *

if config.already_installed("integrations"):
    print("Already installed.")
    exit(0)

open(config.install_flag_filename("shell2"), 'w').close()

if config.debug_mode():
    configure_logger(level=DEBUG)
    configure_logger(files.move_safe, level=DEBUG)

debug(f"Config directory is:         {config.project_dir}")
debug(f"Installation directory is:   {config.install_dir}")
debug(f"Machine-local directory is:  {config.local_dir}")
debug(f"Preconfig directory is:      {config.move_dir}")

config.add_safe("~/.tmux.conf", "programs/tmux.conf")
config.add_safe("~/.gitconfig", "programs/gitconfig")
config.add_safe("~/.gitignore_global", "programs/gitignore_global")
