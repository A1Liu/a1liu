#!/usr/bin/env python3
import os, sys
install_dir = os.path.dirname(os.path.realpath(__file__))
project_dir = os.path.dirname(install_dir)
sys.path.insert(0, os.path.join(project_dir, 'programs'))
from aliu import config

should_undo = len(sys.argv) == 2 and sys.argv[1] == '--undo'
if config.already_installed("shell") != should_undo:
    print("Nothing to do.")
    exit(0)

if should_undo:
    config.remove_replace("~/.bashrc")
    config.remove_replace("~/.bash_profile")
    config.remove_replace("~/.inputrc")
    config.remove_replace("~/.zshrc")
    config.remove_replace("~/.zprofile")

    os.remove(config.install_flag_filename("shell"))
    print("Shell config uninstalled successfully.")
    exit(0)

print_template = f"""#!/bin/sh

export CFG_DIR="{config.project_dir}"
CUR_SHELL="$(basename "$0" 2>/dev/null || echo "$0" | tr -d "-")"
IS_INTERACTIVE_SHELL=%s

. "{config.project_dir}/programs/shells/dispatch"
"""

config.debug("print_template=",
             print_template.strip().replace('\n', '\n' + ' ' * 14 + '='),
             sep='')

with open(os.path.join(config.local_dir, "shell_init"), 'w') as f:
    f.write(print_template % "false")
with open(os.path.join(config.local_dir, "shell_interact_init"), 'w') as f:
    f.write(print_template % "true")

config.add_safe("~/.bash_profile", "local/shell_interact_init")
config.add_safe("~/.bashrc", "local/shell_interact_init")
config.add_safe("~/.inputrc", "programs/shells/inputrc")
config.add_safe("~/.zshrc", "local/shell_interact_init")
config.add_safe("~/.zprofile", "local/shell_init")

# Confirm install
open(config.install_flag_filename("shell"), 'w').close()
print("Shell config installed successfully.")
