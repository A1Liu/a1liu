#!/usr/bin/env python3
import os, sys
install_dir = os.path.dirname(os.path.realpath(__file__))
project_dir = os.path.dirname(install_dir)
sys.path.insert(0, os.path.join(project_dir, 'programs'))
from aliu import config
import platform

should_undo = len(sys.argv) == 2 and sys.argv[1] == '--undo'
if config.already_installed("vim") != should_undo:
    print("Nothing to do.")
    exit(0)

config.debug(f"Config directory is:         {config.project_dir}")
config.debug(f"Installation directory is:   {config.install_dir}")
config.debug(f"Machine-local directory is:  {config.local_dir}")
config.debug(f"Preconfig directory is:      {config.move_dir}")

vim_folder = "~/vimfiles" if platform.system() else "~/.vim"

if should_undo:
    config.remove_replace("~/.vimrc")
    config.remove_replace(vim_folder)

    os.remove(config.install_flag_filename("vim"))
    print("Vim config uninstalled.")
    exit(0)

config.add_safe("~/.vimrc", "programs/vim/init.vim")
config.add_safe(vim_folder, "programs/vim")

# Confirm install
open(config.install_flag_filename("vim"), 'w').close()
print("Vim config installed.")
