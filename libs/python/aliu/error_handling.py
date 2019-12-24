import inspect, traceback


def handle_exception(*args, **kwargs):
    exception, frame_object = args[0:2]
    args = args[2:]
    frameinfo = inspect.getframeinfo(frame_object)
    lines = traceback.format_exc().strip().split('\n')[3:]
    tb_str = '\n'.join(lines)

    print("File \"%s\", line %s:" % (frameinfo.filename, frameinfo.lineno))
    source = None if frameinfo.code_context is None else frameinfo.code_context[
        0].strip()
    print("  Source:\n    %s" % source)
    print("  Traceback (most recent call last):\n    %s" %
          tb_str.replace('\n', '\n  ').strip())


def tryfail(*args, **kwargs):
    try:
        func = args.pop(0)
        func, handler = func
        if not callable(handler):
            output = handler
            if isinstance(handler, dict):
                handler = lambda e, *args, **kwargs: output[e] if isinstance(
                    e, type) else output[e.__class__]
            else:
                handler = lambda *args, **kwargs: output
    except TypeError:
        handler = handle_exception

    try:
        return func(*args, **kwargs)
    except Exception as e:
        return handler(e, inspect.currentframe().f_back, *args, **kwargs)
