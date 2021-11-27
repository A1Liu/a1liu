#!/usr/bin/env python3
import os, sys
install_dir = os.path.dirname(os.path.realpath(__file__))
project_dir = os.path.dirname(install_dir)
sys.path.insert(0, os.path.join(project_dir, 'programs'))
from aliu import config

if config.already_installed("shell"):
    print("Already installed.")
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

# Confirm install
open(config.install_flag_filename("shell"), 'w').close()
