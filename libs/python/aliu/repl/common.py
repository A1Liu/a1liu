from aliu.keyboard import KeyCode
from aliu.repl import flags

# if sys.platform == 'win32':
#     import msvcrt
#     getch = msvcrt.getch

def _char_repr(char):
    return repr(char)[1:-1]

def _repr_buffer(buffer):
    return ''.join([_char_repr(c) for c in buffer])

class _Repl:

    def __init__(self, prompt = '$ ', continuation = '... '):
        self.prompt = prompt
        self.continuation = continuation

    def read_key(self):
        return None, None

    def readline(self, prompt):
        """Reads data from the user, returning it in a list of semantically
        meaningful chunks. The default behavior is to return a list
        of keycodes."""
        self.print(prompt)
        command_buffer = []
        cursor_location = 0
        while True:
            char, code = self.read_key()
            if code == KeyCode.enter:
                return command_buffer
            elif code == KeyCode.backspace:
                if len(command_buffer) == 0:
                    continue
                self.print(f"\r{prompt}" + ' ' * cursor_location)
                cursor_location -= len(repr(command_buffer[-1])[1:-1])
                del command_buffer[-1]
                self.print(f"\r{prompt}{_repr_buffer(command_buffer)}")
            elif char == KeyCode.ctrl_d:
                self.print('\n')
                return flags.QUIT_REPL
            else:
                cursor_location += len(_char_repr(char))
                command_buffer.append(char)
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

