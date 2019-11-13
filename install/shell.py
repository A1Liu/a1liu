#!/usr/bin/env python3
import os,sys
install_dir = os.path.dirname(os.path.realpath(__file__))
project_dir = os.path.dirname(install_dir)
sys.path.insert(0, os.path.join(project_dir, 'libs', 'python'))
from aliu import files
from aliu import config
from aliu.logging import *

if config.already_installed("shell"):
    print("Already installed.")
    exit(0)
else:
    with open(config.install_flag_filename("shell"), 'w') as f:
        pass

if config.debug_mode():
    configure_logger(level = DEBUG)
    configure_logger(files.move_safe, level = DEBUG)

local_dir = os.path.join(project_dir, 'local')
move_dir = os.path.join(local_dir, 'preconf')

debug(f"Config directory is:         {project_dir}")
debug(f"Installation directory is:   {install_dir}")
debug(f"Machine-local directory is:  {local_dir}")
debug(f"Preconfig directory is:      {move_dir}")

if os.path.isfile(move_dir):
    raise Exception("Move directory is a file!")
if not os.path.isdir(move_dir):
    os.makedirs(move_dir)

print_template = """#!/bin/sh

export CFG_DIR="$CFG_DIR"
CUR_SHELL="$(basename "$0" 2>/dev/null || echo "$0" | tr -d "-")"
IS_INTERACTIVE_SHELL=%s

. "$CFG_DIR/shells/dispatch"
"""

debug("print_template=", print_template.replace('\n', '\n' + ' ' * 14 + '='), sep='')

@log_function
def add_safe(name, src):
    debug("hi")
    move_path = os.path.join(move_dir, name)
    output_path = os.path.join(os.path.expanduser('~'), name)
    link_path = os.path.join(project_dir, src)
    if not config.dry_run():
        if os.path.exists(output_path):
            files.move_safe(output_path, move_path)
        os.symlink(link_path, output_path, os.path.isdir(src))
    else:
        print(f"link_path={link_path}")
        print(f"output_path={output_path}")
        if os.path.exists(output_path):
            print(f"`output_path` exists, would have to move it")
        print(f"Would symlink `link_path` to `output_path`")

add_safe(".vimrc", "programs/neovim/init.vim")
add_safe(".vim", "programs/neovim")
add_safe(".bashrc", "local/shell_interact_init")
add_safe(".bash_profile", "local/shell_interact_init")
add_safe(".zshrc", "local/shell_interact_init")
add_safe(".gitconfig", "programs/gitconfig")
add_safe(".gitignore_global", "programs/gitignore_global")
add_safe(".tmux.conf", "programs/tmux.conf")

