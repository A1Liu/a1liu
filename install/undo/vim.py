#!/usr/bin/env python3
import os, sys
import platform
from pathlib import Path
install_dir = os.path.dirname(os.path.realpath(__file__))
project_dir = os.path.dirname(install_dir)
sys.path.insert(0, os.path.join(project_dir, 'libs', 'python'))
from aliu import files
from aliu import config
from aliu.logging import *
import platform

if not config.already_installed("vim"):
    print("Vim config not installed.")
    exit(0)

if config.debug_mode():
    configure_logger(level=DEBUG)
    configure_logger(files.move_safe, level=DEBUG)

debug(f"Config directory is:         {config.project_dir}")
debug(f"Installation directory is:   {config.install_dir}")
debug(f"Machine-local directory is:  {config.local_dir}")
debug(f"Preconfig directory is:      {config.move_dir}")

config.remove_replace("~/.vimrc")
if platform.system() == "Windows":
    config.remove_replace("~/vimfiles")
else:
    config.remove_replace("~/.vim")

os.remove(config.install_flag_filename("vim"))
