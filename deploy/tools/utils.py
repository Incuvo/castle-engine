from __future__ import with_statement

from fabric.api import hide, settings

from fabtools.utils import run_as_root


def is_mongodb_service_running():

    with settings(hide('running', 'stdout', 'stderr', 'warnings'), warn_only=True):
        res = run_as_root('service mongodb status')
        return not ('stop' in str(res))

def booleanize(value):
    """Return value as a boolean."""

    true_values = ("yes", "true", "1")
    false_values = ("no", "false", "0")

    if isinstance(value, bool):
        return value

    if value.lower() in true_values:
        return True

    elif value.lower() in false_values:
        return False

    raise TypeError("Cannot booleanize ambiguous value '%s'" % value)