#!/usr/bin/env python3
from aliu import files
from aliu import config
from aliu.logging import *
import platform

if not config.already_installed("shell"):
    print("Shell config not installed.")
    exit(0)

if config.debug_mode():
    configure_logger(level=DEBUG)
    configure_logger(files.move_safe, level=DEBUG)

config.remove_replace("~/.bashrc")
config.remove_replace("~/.bash_profile")
config.remove_replace("~/.inputrc")
config.remove_replace("~/.zshrc")

os.remove(config.install_flag_filename("shell"))

print("Shell config uninstalled successfully.")
