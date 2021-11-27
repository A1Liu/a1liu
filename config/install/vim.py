#!/usr/bin/env python3
import os, sys
install_dir = os.path.dirname(os.path.realpath(__file__))
project_dir = os.path.dirname(install_dir)
sys.path.insert(0, os.path.join(project_dir, 'programs'))
from aliu import config
import platform

if config.already_installed("vim"):
    print("Already installed.")
    exit(0)

config.add_safe("~/.vimrc", "programs/vim/init.vim")
if platform.system() == "Windows":
    config.add_safe("~/vimfiles", "programs/vim")
else:
    config.add_safe("~/.vim", "programs/vim")

# Confirm install
open(config.install_flag_filename("vim"), 'w').close()
