import sys

if sys.platform == 'win32':
    import msvcrt
    getch = msvcrt.getch
else:
    import tty, termios
    # https://stackoverflow.com/questions/1052107/reading-a-single-character-getch-style-in-python-is-not-working-in-unix
    def getch():
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

ENTER = '\r'
DELETE = '\x7f'

def _char_repr(char):
    return repr(char)[1:-1]

def _repr_buffer(buffer):
    return ''.join([_char_repr(c) for c in buffer])

def handle_enter(repl):
    repl.print(repl.eval(repl.current_buffer))
    repl.current_buffer = []
    repl.current_index = len(repl.prompt)
    print(f"{repl.prompt}", end = '', flush = True)

def handle_delete(repl):
    if len(repl.current_buffer) > 0:
        print(f"\r{repl.prompt}" + ' ' * repl.current_index, end = '', flush = True)
        repl.current_index -= len(repl.current_buffer[-1])
        del repl.current_buffer[-1]
        print(f"\r{repl.prompt}{_repr_buffer(repl)}", end = '', flush = True)

class Repl:

    def __init__(self, prompt = '$ ', callbacks = {}):
        self.prompt = prompt
        self.current_buffer = []
        self.current_index = 0
        self.should_continue = True
        self.callbacks = {
            ENTER  : handle_enter,
            DELETE : handle_delete,
            **callbacks
        }

    def getch(self):
        return getch()

    def eval(self, buffer):
        return _repr_buffer(buffer)

    def print(self, value):
        print(f"\n{value}")

    def handle_all(self, char):
        if char in self.callbacks:
            self.callbacks[char](self)
        else:
            self.fallback(char)

    def fallback(self, char):
        self.current_buffer.append(char)
        print(_char_repr(char), end = '', flush = True)
        self.current_index += len(char)

    def handle_exception(self, e):
        print(e)
        self.should_continue = False

    def run(self):
        print(f"{self.prompt}", end = '', flush = True)
        self.current_index = len(self.prompt)

        while self.should_continue:
            try:
                char = self.getch()
            except Exception as e:
                self.handle_exception(e)
            if self.should_continue:
                self.handle_all(char)

