#!/usr/bin/env python3
import os, sys
import platform
from pathlib import Path
install_dir = os.path.dirname(os.path.realpath(__file__))
project_dir = os.path.dirname(install_dir)
sys.path.insert(0, os.path.join(project_dir, 'programs'))
from aliu import files
from aliu import config
from aliu.logging import *

if config.already_installed("vim"):
    print("Already installed.")
    exit(0)

if config.debug_mode():
    configure_logger(level=DEBUG)
    configure_logger(files.move_safe, level=DEBUG)

config.add_safe("~/.vimrc", "programs/vim/init.vim")
if platform.system() == "Windows":
    config.add_safe("~/vimfiles", "programs/vim")
else:
    config.add_safe("~/.vim", "programs/vim")

# Confirm install
open(config.install_flag_filename("vim"), 'w').close()
