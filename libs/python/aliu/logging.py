import inspect, re, sys, os

def _get_logger_id(obj):
    if isinstance(obj, str):
        return (obj, None)
    elif hasattr(obj, '_call_'):
        filename = inspect.getsourcefile(obj)
        return (os.path.relpath(filename), obj._name_)
    elif isinstance(obj, inspect.types.FrameType) or obj is None:
        if obj is None:
            obj = inspect.currentframe().f_back.f_back
        frame_info = inspect.getframeinfo(obj)
        if frame_info.function == '<module>':
            return (os.path.relpath(frame_info.filename), None)
        else:
            return (os.path.relpath(frame_info.filename), frame_info.function)
    else:
        raise AssertionError("Incorrect type passed for _get_logger (type=%s)" % (type(obj)))

class Logger(object):
    TRACE = 10
    DEBUG = 20
    INFO = 30
    WARN = 40
    ERROR = 50
    REGISTERED_LOGGERS = {}

    def __init__(self, obj = None):
        global _get_logger_id
        self.level = WARN
        self.id = _get_logger_id(obj)
        self.prefix = True
        if self.id in Logger.REGISTERED_LOGGERS:
            raise AssertionError("Rebuilt existing logger.")
        else:
            Logger.REGISTERED_LOGGERS[self.id] = self
            if (self.id[0], None) not in Logger.REGISTERED_LOGGERS:
                Logger(obj = self.id)

    def get_prefix(self):
        if self.id[1] is None:
            return str(self.id[0])
        else:
            return ':'.join(self.id)

    def log(self, *args, level = 20, sep = ' ', end = '\n'):
        if level >= self.level:
            print(self.id[0], *args, sep = sep, end = end, file = sys.stderr)

def _get_logger(obj):
    frame = inspect.currentframe().f_back.f_back
    id = _get_logger_id(frame)
    if id in Logger.REGISTERED_LOGGERS:
        return Logger.REGISTERED_LOGGERS[id]
    return Logger(frame)

def get_logger(obj = None):
    return _get_logger(obj)

def configure_logger(obj = None, level = None):
    logger = _get_logger(obj)
    logger.level = level
    return logger

def log_function(level = None):
    def decorator(func):
        logger = _get_logger(func)
        if level is not None:
            logger.level = level
        return func
    return decorator

def debug(*args, sep = ' '):
    logger = _get_logger(None)
    prefix = '%s ~ ' % inspect.getframeinfo( inspect.currentframe().f_back ).lineno
    message = sep.join(args)
    for line in message.split('\n'):
        logger.log(prefix + line, level = Logger.DEBUG)

TRACE = Logger.TRACE
DEBUG = Logger.DEBUG
INFO = Logger.INFO
WARN = Logger.WARN
ERROR = Logger.ERROR
