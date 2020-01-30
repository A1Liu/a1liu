import os, sys
from aliu.logging import *


def move_safe(src, dest, prefix='_'):
    src, dest = os.path.expanduser(src), os.path.expanduser(dest)
    debug(f"move_safe(src={src}, dest={dest})")
    if not os.path.exists(src):
        debug(f"Source doesn't exist! (src={src})")
        return

    if os.path.exists(dest):
        debug(f"Destination exists! (dest={dest})")
        replace_dest = os.path.join(os.path.dirname(dest),
                                    prefix + os.path.basename(dest))
        move_safe(dest, replace_dest, prefix)

    os.rename(src, dest)

    # if os.path.isdir(src):
    #     debug(f"Source is a directory (src={src})")
    # # elif os.path.islink(src):
    # #     debug(f"Source is a symbolic link (src={src})")
    # #     with open(src, 'r') as f:
    # #         source_data = f.read()
    # #     with open(dest, 'w') as f:
    # #         f.write(source_data)
    # #     os.remove(src)
    # elif os.path.isfile(src):
    #     debug(f"Source is a file (src={src})")
    #     with open(src, 'r') as f:
    #         source_data = f.read()
    #     with open(dest, 'w') as f:
    #         f.write(source_data)
    #     os.remove(src)
    # else:
    #     debug(f"Case not handled (src={src})")
