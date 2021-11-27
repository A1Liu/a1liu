#!/usr/bin/env python3
import os, sys
undo_dir = os.path.dirname(os.path.realpath(__file__))
install_dir = os.path.dirname(undo_dir)
project_dir = os.path.dirname(install_dir)
sys.path.insert(0, os.path.join(project_dir, 'libs', 'python'))
from aliu import config

if not config.already_installed("shell"):
    print("Shell config not installed.")
    exit(0)

config.remove_replace("~/.bashrc")
config.remove_replace("~/.bash_profile")
config.remove_replace("~/.inputrc")
config.remove_replace("~/.zshrc")

os.remove(config.install_flag_filename("shell"))

print("Shell config uninstalled successfully.")
