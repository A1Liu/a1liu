import logging, inspect, re, sys, os
from types import ModuleType
from logging import DEBUG
from logging import INFO
from logging import WARN
from logging import ERROR

def __configure_logger(logger, level = None, handlers = None):

    if level is not None:
        logger.setLevel(level)
    elif not hasattr(logger, '__aliu__'):
        logger.setLevel(WARN)

    if handlers is not None:
        logger.handlers = handlers
    elif not hasattr(logger, '__aliu__'):
        logger.handlers = []
        handler = logging.StreamHandler()
        handler.setLevel(logging.DEBUG)
        handler.setFormatter(logging.Formatter('%(name)s:%(message)s'))
        logger.addHandler(handler)
    logger.__aliu__ = True

def __get_logger(obj):
    if isinstance(obj, logging.Logger):
        return obj
    if isinstance(obj, str):
        return logging.getLogger(obj)
    elif hasattr(obj, '__call__'):
        filename = inspect.getsourcefile(obj)
        name = "%s:%s" % (os.path.relpath(filename), obj.__name__)
        return logging.getLogger(name)
    elif isinstance(obj, inspect.types.FrameType):
        frame_info = inspect.getframeinfo(obj)
        name = "%s:%s" % (os.path.relpath(frame_info.filename), frame_info.function)
        return logging.getLogger(name)
    elif obj is None:
        frame_info = inspect.getframeinfo(inspect.currentframe().f_back.f_back)
        if frame_info.function == '<module>':
            name = "%s" % os.path.relpath(frame_info.filename)
        else:
            name = "%s:%s" % (os.path.relpath(frame_info.filename), frame_info.function)
        return logging.getLogger(name)
    else:
        raise AssertionError("Incorrect type passed for __get_logger (type=%s)" % (type(obj)))


def get_logger(obj = None):
    logger = __get_logger(obj)
    if not hasattr(logger, '__aliu__'):
        __configure_logger(logger)
    return logger

def configure_logger(obj = None, level = None, handlers = None):
    logger = __get_logger(obj)
    __configure_logger(logger, level = level, handlers = handlers)
    return logger

def debug(*args, sep = ' '):
    logger = __get_logger(None)
    prefix = '%s ~ ' % inspect.getframeinfo( inspect.currentframe().f_back ).lineno
    message = sep.join(args)
    for line in message.split('\n'):
        logger.debug(prefix + line)

