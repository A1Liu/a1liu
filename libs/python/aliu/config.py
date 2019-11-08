import os, subprocess

aliu_dir = os.path.dirname(os.path.realpath(__file__))
python_dir = os.path.dirname(aliu_dir)
libs_dir = os.path.dirname(python_dir)
project_dir = os.path.dirname(libs_dir)
flag_dir = os.path.join(project_dir, 'local', 'flags')

def debug_mode():
    return 'DEBUG' in os.environ and os.environ['DEBUG'] == 'true'

def dry_run():
    return 'DRY_RUN' in os.environ and os.environ['DRY_RUN'] == 'true'

def run_command(*args):
    return subprocess.run(args, check = True)

def flag_filename(flag):
    return os.path.join(flag_dir, flag)

def install_flag_filename(flag):
    return os.path.join(flag_dir, "installed-" + flag)

def check_flag(flag):
    return os.path.exists(flag_filename(flag))

def already_installed(script):
    return os.path.exists(install_flag_filename(script))
