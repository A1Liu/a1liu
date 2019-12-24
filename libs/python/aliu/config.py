import os, subprocess

__aliu_dir = os.path.dirname(os.path.realpath(__file__))
__python_dir = os.path.dirname(__aliu_dir)
libs_dir = os.path.dirname(__python_dir)
project_dir = os.path.dirname(libs_dir)
install_dir = os.path.join(project_dir, 'install')
local_dir = os.path.join(project_dir, 'local')
flags_dir = os.path.join(local_dir, 'flags')
data_dir = os.path.join(project_dir, 'data')


def debug_mode():
    return 'DEBUG' in os.environ and os.environ['DEBUG'] == 'true'


def dry_run():
    return 'DRY_RUN' in os.environ and os.environ['DRY_RUN'] == 'true'


def run_command(*args):
    return subprocess.run(args, check=True)


def flag_filename(flag):
    return os.path.join(flags_dir, flag)


def install_flag_filename(flag):
    return os.path.join(flags_dir, "installed-" + flag)


def check_flag(flag):
    return os.path.exists(flag_filename(flag))


def already_installed(script):
    return os.path.exists(install_flag_filename(script))


def local_file(path, mode='r'):
    file_path = os.path.join(local_dir, path)
    if not os.path.exists(file_path) and mode == 'r':
        open(file_path, 'w').close()
    return open(file_path, mode)


def data_file(path, mode='r'):
    file_path = os.path.join(data_dir, path)
    if not os.path.exists(file_path) and mode == 'r':
        open(file_path, 'w').close()
    return open(file_path, mode)
