#!/usr/bin/env python3
import os, sys
from pathlib import Path
install_dir = os.path.dirname(os.path.realpath(__file__))
project_dir = os.path.dirname(install_dir)
sys.path.insert(0, os.path.join(project_dir, 'libs', 'python'))
from aliu import config
import platform

if not config.already_installed("vim"):
    print("Vim config not installed.")
    exit(0)

config.debug(f"Config directory is:         {config.project_dir}")
config.debug(f"Installation directory is:   {config.install_dir}")
config.debug(f"Machine-local directory is:  {config.local_dir}")
config.debug(f"Preconfig directory is:      {config.move_dir}")

config.remove_replace("~/.vimrc")
if platform.system() == "Windows":
    config.remove_replace("~/vimfiles")
else:
    config.remove_replace("~/.vim")

os.remove(config.install_flag_filename("vim"))
