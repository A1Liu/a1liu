class _ReplFlag:
    def __init__(self):
        pass

READLINE_RETURN_BUFFER = _ReplFlag()
SKIP_PRINTING = _ReplFlag()

SKIP_EVALUATION = _ReplFlag()

CONTINUE_READING = _ReplFlag()

QUIT_REPL = _ReplFlag()


