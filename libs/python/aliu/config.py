import os, subprocess

__aliu_dir = os.path.dirname(os.path.realpath(__file__))
__python_dir = os.path.dirname(__aliu_dir)
libs_dir = os.path.dirname(__python_dir)
project_dir = os.path.dirname(libs_dir)
install_dir = os.path.join(project_dir, 'install')
local_dir = os.path.join(project_dir, 'local')
flags_dir = os.path.join(local_dir, 'flags')
data_dir = os.path.join(project_dir, 'data')
move_dir = os.path.join(local_dir, 'preconf')


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


def add_safe(output_path, src):
    output_path = os.path.expanduser(output_path)
    name = os.path.basename(output_path)
    move_path = os.path.join(move_dir, name)
    link_path = os.path.join(project_dir, src)

    if dry_run():
        print(f"link_path={link_path}")
        print(f"output_path={output_path}")
        if os.path.islink(output_path) or os.path.exists(output_path):
            print(f"`output_path` exists, would have to move it")
        print(f"Would symlink `link_path` to `output_path`")
        return

    if os.path.islink(output_path) or os.path.exists(output_path):
        files.move_safe(output_path, move_path)

    os.symlink(link_path, output_path, os.path.isdir(src))


def remove_replace(src):
    file_path = os.path.expanduser(src)
    previous_file_path = os.path.join(move_dir, src)

    if os.path.exists(file_path):
        os.remove(file_path)
    if os.path.exists(previous_file_path):
        os.rename(previous_file_path, file_path)


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
