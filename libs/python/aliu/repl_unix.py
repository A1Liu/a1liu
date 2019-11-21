import sys
from collections import deque
import tty, termios

ENTER = '\r'
DELETE = '\x7f'

def _char_repr(char):
    return repr(char)[1:-1]

def _repr_buffer(buffer):
    return ''.join([_char_repr(c) for c in buffer])

def handle_enter(repl, char, command_buffer):
    return True

def handle_delete(repl, char, command_buffer):
    if len(command_buffer) > 0:
        repl.print(f"\r{repl.prompt}" + ' ' * sum([len(_char_repr(c)) for c in command_buffer]))
        del command_buffer[-1]
        repl.print(f"\r{repl.prompt}{_repr_buffer(command_buffer)}")

class Repl:
    def __init__(self, prompt = '$ ', callbacks = {}):
        self.prompt = prompt
        self.callbacks = {
            ENTER  : handle_enter,
            DELETE : handle_delete,
            **callbacks
        }

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

    def read(self):
        """
        Reads data from the user, returning it in a list of semantically
        meaningful chunks. The default behavior is to return a list
        of keycodes.
        """
        command_buffer = []
        while True:
            char = self.getch()
            if self.handle_all(char, command_buffer):
                break
            if char in self.callbacks:
                if self.callbacks[char](self, char, command_buffer):
                    break
            else:
                if self.fallback(char, command_buffer):
                    break
        return command_buffer

    def eval(self, buffer):
        """
        Evaluates the data stored in the given buffer. This method is typically
        overriden.
        """
        return f"'{_repr_buffer(buffer)}'"

    def print(self, value):
        """
        Prints the data to the screen.
        """
        print(f"{value}", end = '', flush = True)

    def handle_all(self, char, command_buffer):
        pass

    def fallback(self, char, command_buffer):
        command_buffer.append(char)
        self.print(_char_repr(char))

    def run(self):
        self.print(f"{self.prompt}")
        while True:
            self.current_index = len(self.prompt)
            command_buffer = self.read()
            value = self.eval(command_buffer)
            self.print(f"\n{value}")
            self.print(f"\n{self.prompt}")


