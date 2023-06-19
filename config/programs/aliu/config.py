import os, subprocess

__aliu_dir = os.path.dirname(os.path.realpath(__file__))
programs_dir = os.path.dirname(__aliu_dir)
project_dir = os.path.dirname(programs_dir)
install_dir = os.path.join(project_dir, 'install')
local_dir = os.path.join(project_dir, 'local')
flags_dir = os.path.join(local_dir, 'flags')
move_dir = os.path.join(local_dir, 'preconf')


def debug_mode():
    return 'DEBUG' in os.environ and os.environ['DEBUG'] == 'true'


def dry_run():
    return 'DRY_RUN' in os.environ and os.environ['DRY_RUN'] == 'true'


def debug(*args, sep=' '):
    if not debug_mode():
        return

    prefix = '%s ~ ' % inspect.getframeinfo(
        inspect.currentframe().f_back).lineno
    message = sep.join([str(arg) for arg in args])
    for line in message.split('\n'):
        print(prefix + line)


def move_safe(src, dest, prefix='_'):
    debug("move_safe(src={}, dest={})".format(src, dest))
    if not os.path.exists(src) and not os.path.islink(src):
        debug("Source doesn't exist! (src={})".format(src))
        return

    if os.path.islink(dest) or os.path.exists(dest):
        debug("Destination exists! (dest={})".format(dest))
        replace_dest = os.path.join(os.path.dirname(dest),
                                    prefix + os.path.basename(dest))
        move_safe(dest, replace_dest, prefix)

    os.rename(src, dest)


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
        print("link_path={}".format(link_path))
        print("output_path={}".format(output_path))
        if os.path.islink(output_path) or os.path.exists(output_path):
            print("`output_path` exists, would have to move it")
        print(f"Would symlink `link_path` to `output_path`")
        return

    if os.path.islink(output_path) or os.path.exists(output_path):
        move_safe(output_path, move_path)

    os.makedirs(os.path.dirname(output_path), mode = 0o777, exist_ok = True) 
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

