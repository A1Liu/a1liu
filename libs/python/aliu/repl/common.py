from aliu.keyboard import KeyCode
from aliu.repl import flags
from collections import deque

def _char_repr(char):
    return repr(char)[1:-1]

def _repr_buffer(buffer):
    return ''.join([_char_repr(c) for c in buffer])

class _CurrentLine:
    def __init__(self, prompt):
        self.buffer = []
        self.cursor_location = 0
        self.prompt = prompt

def handle_enter(repl, line, char, code):
    return flags.READLINE_RETURN_BUFFER

def handle_backspace(repl, line, char, code):
    if len(line.buffer) == 0:
        return
    repl.print(f"\r{line.prompt}" + ' ' * sum(len(_char_repr(c)) for c in line.buffer))
    line.cursor_location -= len(repr(line.buffer[-1])[1:-1])
    del line.buffer[-1]
    repl.print(f"\r{line.prompt}{_repr_buffer(line.buffer)}")

def handle_ctrl_d(repl, line, char, code):
    repl.print('\n')
    return flags.QUIT_REPL

def handle_arrow_keys(repl, line, char, code):
    pass

class _Repl:

    def __init__(self, prompt = '$ ', continuation = '... ', handlers = {}):
        self.prompt = prompt
        self.continuation = continuation
        self.history = deque()
        self.handlers = {
            KeyCode.enter:handle_enter,
            KeyCode.backspace:handle_backspace,
            KeyCode.ctrl_d:handle_ctrl_d,
            KeyCode.up:handle_arrow_keys,
            KeyCode.down:handle_arrow_keys,
            KeyCode.left:handle_arrow_keys,
            KeyCode.right:handle_arrow_keys,
            **handlers
        }

    def read_key(self):
        return None, None

    def readline(self, prompt):
        """Reads data from the user, returning it in a list of semantically
        meaningful chunks. The default behavior is to return a list
        of keycodes."""
        self.print(prompt)
        line = _CurrentLine(prompt)
        while True:
            char, code = self.read_key()
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

    def parse(self, buffer):
        if len(buffer) > 0 and buffer[-1] == '\\':
            return flags.CONTINUE_READING
        else:
            return ''.join([repr(c)[1:-1] for c in buffer])

    def eval(self, parse_tree):
        """Evaluates the data stored in the given buffer. This method is typically
        overriden."""
        return f"'{parse_tree}'"

    def print(self, value):
        """Prints the data to the screen."""
        print(f"{value}", end = '', flush = True)

    def handle_read_error(self, exception, command_buffer):
        if isinstance(exception, KeyboardInterrupt):
            self.print('\n')
            return flags.QUIT_REPL
        elif isinstance(exception, Exception):
            raise exception
        return command_buffer

    def run(self):
        """Run the REPL."""
        while True:
            command_buffer = []
            try:
                command_buffer = self.readline(self.prompt)
            except KeyboardInterrupt as e:
                command_buffer = self.handle_read_error(e, command_buffer)
            except Exception as e:
                command_buffer = self.handle_read_error(e, command_buffer)

            if command_buffer is flags.QUIT_REPL:
                break

            parsed_value = self.parse(command_buffer)
            while parsed_value is flags.CONTINUE_READING:
                try:
                    line = self.readline(self.continuation)
                    if line is flags.QUIT_REPL:
                        break
                    command_buffer += line
                    parsed_value = self.parse(command_buffer)
                except KeyboardInterrupt as e:
                    parsed_value = self.handle_read_error(e, command_buffer)
                except Exception as e:
                    parsed_value = self.handle_read_error(e, command_buffer)
            value = self.eval(parsed_value)
            if value is flags.QUIT_REPL:
                break
            self.print(f"\n{value}\n")

