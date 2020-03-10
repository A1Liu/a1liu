#!/usr/bin/env python3
from aliu import files
from aliu import config
from aliu.logging import *

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

remove_replace("~/.vimrc")
remove_replace("~/.vim")
remove_replace("~/.bashrc")
remove_replace("~/.bash_profile")
remove_replace("~/.inputrc")
remove_replace("~/.zshrc")
