import sys
from collections import deque
import tty, termios

ENTER = '\r'
DELETE = '\x7f'
CTRL_D = '\x04'

def _char_repr(char):
    return repr(char)[1:-1]

def _repr_buffer(buffer):
    return ''.join([_char_repr(c) for c in buffer])

def handle_delete(repl, char, command_buffer):
    if len(command_buffer) > 0:
        repl.print(f"\r{repl.prompt}" + ' ' * sum([len(_char_repr(c)) for c in command_buffer]))
        del command_buffer[-1]
        repl.print(f"\r{repl.prompt}{_repr_buffer(command_buffer)}")

def handle_arrow_keys(repl, char, command_buffer):
    pass

class ReplFlag:
    def __init__(self):
        pass

class Repl:

    CONTINUE_READING = ReplFlag()
    QUIT_REPL = ReplFlag()

    def __init__(self, prompt = '$ ', continuation = '... '):
        self.prompt = prompt
        self.continuation = continuation

    def getch(self):
        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        try:
            tty.setraw(sys.stdin.fileno())
            ch = sys.stdin.read(1)
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
        if ch == '\x03':
            raise KeyboardInterrupt()
        return ch

    def read_key(self):
        return self.getch()

    def readline(self, prompt):
        """Reads data from the user, returning it in a list of semantically
        meaningful chunks. The default behavior is to return a list
        of keycodes."""
        self.print(prompt)
        command_buffer = []
        cursor_location = 0
        while True:
            char = self.read_key()
            if char == ENTER:
                return command_buffer
            elif char == DELETE:
                if len(command_buffer) == 0:
                    continue
                self.print(f"\r{prompt}" + ' ' * cursor_location)
                cursor_location -= len(repr(command_buffer[-1])[1:-1])
                del command_buffer[-1]
                self.print(f"\r{prompt}{_repr_buffer(command_buffer)}")
            elif char == CTRL_D:
                self.print('\n')
                return Repl.QUIT_REPL
            else:
                cursor_location += len(_char_repr(char))
                command_buffer.append(char)
                self.print(_char_repr(char))

    def parse(self, buffer):
        if len(buffer) > 0 and buffer[-1] == '\\':
            return Repl.CONTINUE_READING
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
            return Repl.QUIT_REPL
        return command_buffer

    def run(self):
        """Run the REPL."""
        while True:
            command_buffer = None
            try:
                command_buffer = self.readline(self.prompt)
            except KeyboardInterrupt as e:
                command_buffer = self.handle_read_error(e, command_buffer)
            except Exception as e:
                command_buffer = self.handle_read_error(e, command_buffer)

            if command_buffer is Repl.QUIT_REPL:
                break

            parsed_value = self.parse(command_buffer)
            while parsed_value is Repl.CONTINUE_READING:
                try:
                    line = self.readline(self.continuation)
                    if line is Repl.QUIT_REPL:
                        break
                    command_buffer += line
                    parsed_value = self.parse(command_buffer)
                except KeyboardInterrupt as e:
                    parsed_value = self.handle_read_error(e, command_buffer)
                except Exception as e:
                    parsed_value = self.handle_read_error(e, command_buffer)
            value = self.eval(parsed_value)
            if value is Repl.QUIT_REPL:
                break
            self.print(f"\n{value}\n")

