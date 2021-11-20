import os, sys
from aliu.logging import *


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
