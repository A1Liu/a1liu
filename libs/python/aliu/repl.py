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

def _repr_buffer(state):
    return ''.join([char_repr(c) for c in state.current_buffer])

def initialize_state(state):
    return state

def char_repr(char):
    return repr(char)[1:-1]

def handle_all(state, char):
    if char in state.callbacks:
        state.callbacks[char](state)
    else:
        state.fallback(state, char)

def fallback(state, char):
    state.current_buffer.append(char)
    print(char_repr(char), end = '', flush = True)
    state.current_index += len(char)

def repl_evaluate(state, buffer):
    return "'" + _repr_buffer(state) + "'"

def repl_print(state, value):
    print(f"\n{value}")

def handle_enter(state):
    state.print(state, state.evaluate(state, state.current_buffer))
    state.current_buffer = []
    state.current_index = len(state.prompt)
    print(f"{state.prompt}", end = '', flush = True)

def handle_delete(state):
    if len(state.current_buffer) > 0:
        print(f"\r{state.prompt}" + ' ' * state.current_index, end = '', flush = True)
        state.current_index -= len(state.current_buffer[-1])
        del state.current_buffer[-1]
        print(f"\r{state.prompt}{_repr_buffer(state)}", end = '', flush = True)

def should_continue(state):
    return True

def repl(initialize_state = initialize_state, callbacks = {}):
    callbacks = {
        '\r'   : handle_enter,
        '\x7f' : handle_delete,
        **callbacks
    }

    state = lambda: None
    state.prompt = '$ '
    state.current_buffer = []
    state.current_index = 0
    state.fallback = fallback
    state.handle_all = handle_all
    state.getch = lambda state: getch()
    state.callbacks = callbacks
    state.should_continue = should_continue
    state.evaluate = repl_evaluate
    state.print = repl_print
    state = initialize_state(state)

    print(f"{state.prompt}", end = '', flush = True)
    state.current_index = len(state.prompt)

    while state.should_continue(state):
        try:
            char = state.getch(state)
        except KeyboardInterrupt:
            print()
            break
        handle_all(state, char)
