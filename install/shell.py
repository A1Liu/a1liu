#!/usr/bin/env python3
import os,sys
dirname = os.path.dirname
install_dir = dirname(os.path.realpath(__file__))
project_dir = dirname(install_dir)
sys.path.insert(0, os.path.join(project_dir, 'libs', 'python'))
from aliu import files
from aliu.logging import *

logger = configure_logger(files.move_safe, level = DEBUG)

if 'DEBUG' in os.environ and os.environ['DEBUG'] == 'true':
    logger = configure_logger(level = DEBUG)

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

files.move_safe('asdf', 'asdf')
