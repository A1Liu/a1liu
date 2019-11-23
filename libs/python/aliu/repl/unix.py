import sys
import tty, termios
from .keyboard import KeyCode

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

_key_codes = {
    '\x01'    : KeyCode.ctrl_a,
    '\x02'    : KeyCode.ctrl_b,
    '\x03'    : KeyCode.ctrl_c,
    '\x04'    : KeyCode.ctrl_d,
    '\x05'    : KeyCode.ctrl_e,
    '\x06'    : KeyCode.ctrl_f,
    '\x07'    : KeyCode.ctrl_g,
    '\x08'    : KeyCode.ctrl_h,
    '\x09'    : KeyCode.ctrl_i,
    '\x10'    : KeyCode.ctrl_j,
    '\x0b'    : KeyCode.ctrl_k,
    '\x0c'    : KeyCode.ctrl_l,
    '\x0d'    : KeyCode.ctrl_m,
    '\x0e'    : KeyCode.ctrl_n,
    '\x0f'    : KeyCode.ctrl_o,
    '\x10'    : KeyCode.ctrl_p,
    '\x11'    : KeyCode.ctrl_q,
    '\x12'    : KeyCode.ctrl_r,
    '\x13'    : KeyCode.ctrl_s,
    '\x14'    : KeyCode.ctrl_t,
    '\x15'    : KeyCode.ctrl_u,
    '\x16'    : KeyCode.ctrl_v,
    '\x17'    : KeyCode.ctrl_w,
    '\x18'    : KeyCode.ctrl_x,
    '\x19'    : KeyCode.ctrl_y,
    '\x1a'    : KeyCode.ctrl_z,
    '\r'      : KeyCode.enter,
    '\x7f'    : KeyCode.backspace,
    '\x1b[A'  : KeyCode.up,
    '\x1b[B'  : KeyCode.down,
    '\x1b[C'  : KeyCode.right,
    '\x1b[D'  : KeyCode.left,
}


def read_key(repl):
    # return getch(), KeyCode.esc
    char = getch()
    if ord(char) >= 32 and ord(char) < 127:
        return char, KeyCode.printing_character

    while char not in _key_codes and len(char) < 3:
        char += getch()

    if char not in _key_codes:
        print(repr(char))
        raise Exception("Key not in key codes!")
        return char, KeyCode.unrecognized_character
    return char,_key_codes[char]

