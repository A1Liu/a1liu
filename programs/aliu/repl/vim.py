#TODO Abandonded for now.
import sys
from . import flags
from .common import Repl
from .keyboard import KeyCode

if sys.platform == 'linux':
    from .unix import read_key

def handle_enter(repl, line, char, code):
    repl.print('\n')
    return flags.READLINE_RETURN_BUFFER

def handle_backspace(repl, line, char, code):
    if len(line.buffer) == 0:
        return
    repl.print(f"\r{line.prompt}" + ' ' * sum(len(_char_repr(c)) for c in line.buffer))
    line.cursor_location -= len(repr(line.buffer[-1])[1:-1])
    del line.buffer[-1]
    repl.print("\r{}{}".format(line.prompt, _repr_buffer(line.buffer)))

def handle_ctrl_d(repl, line, char, code):
    repl.print('\n')
    return flags.QUIT_REPL

def handle_arrow_keys(repl, line, char, code):
    pass


class VimRepl(Repl):
    def __init__(self, prompt = '$ ', continuation = '... ', handlers = {}):
        super().__init__(prompt, continuation)
        self.handlers = {
            KeyCode.enter:handle_enter,
            KeyCode.backspace:handle_backspace, KeyCode.ctrl_d:handle_ctrl_d,
            KeyCode.up:handle_arrow_keys,
            KeyCode.down:handle_arrow_keys,
            KeyCode.left:handle_arrow_keys,
            KeyCode.right:handle_arrow_keys,
            **handlers
        }

    def readline(self, prompt):
        """Reads data from the user, returning it in a list of semantically
        meaningful chunks. The default behavior is to return a list
        of keycodes."""
        self.print(prompt)
        line = _CurrentLine(prompt)
        while True:
            char, code = read_key(self)
            if code in self.handlers:
                ret_flag = self.handlers[code](self, line, char, code)
                if ret_flag is flags.READLINE_RETURN_BUFFER:
                    return line.buffer
                elif ret_flag is flags.QUIT_REPL:
                    return ret_flag
            else:
                line.cursor_location += len(_char_repr(char))
                line.buffer.append(char)
                self.print(_char_repr(char))

