import sys
from aliu.repl.flags import *

if sys.platform == 'linux':
    from aliu.repl.unix import Repl
