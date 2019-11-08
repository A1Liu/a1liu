import os, subprocess

def debug_mode():
    return 'DEBUG' in os.environ and os.environ['DEBUG'] == 'true'

def dry_run():
    return 'DRY_RUN' in os.environ and os.environ['DRY_RUN'] == 'true'

def run_command(*args):
    return subprocess.run(args, check = True)
