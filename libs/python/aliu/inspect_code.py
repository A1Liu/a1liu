import inspect, traceback, subprocess, os


def getsource(obj):
    return inspect.getsource(obj)


def getfile(obj):
    return inspect.getfile(obj)


def atom(file_name):
    return subprocess.Popen(['open', '-a', 'Atom', os.path.abspath(file_name)])


def editsrc(obj):
    atom(getfile(obj))
