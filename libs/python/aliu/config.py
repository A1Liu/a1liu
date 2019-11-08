import os

def debug_mode():
    return 'DEBUG' in os.environ and os.environ['DEBUG'] == 'true'

def dry_run():
    return 'DRY_RUN' in os.environ and os.environ['DRY_RUN'] == 'true'
