#!/usr/bin/env python3
from aliu import files
from aliu import config
from aliu.logging import *
import platform

if not config.already_installed("shell"):
    print("Shell config not installed.")
    exit(0)

os.remove(config.install_flag_filename("shell"))

if config.debug_mode():
    configure_logger(level=DEBUG)
    configure_logger(files.move_safe, level=DEBUG)

debug(f"Config directory is:         {config.project_dir}")
debug(f"Installation directory is:   {config.install_dir}")
debug(f"Machine-local directory is:  {config.local_dir}")
debug(f"Preconfig directory is:      {config.move_dir}")

config.remove_replace("~/.bashrc")
config.remove_replace("~/.bash_profile")
config.remove_replace("~/.inputrc")
config.remove_replace("~/.zshrc")
config.remove_replace("~/.vimrc")
if platform.system() == "Windows":
    config.remove_replace("~/vimfiles")
else:
    config.remove_replace("~/.vim")
