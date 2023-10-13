"""
Supervisor processes
====================

This module provides high-level tools for managing long-running
processes using `supervisor`_.

.. _supervisor: http://supervisord.org/

"""
from __future__ import with_statement

import utils
import os

from fabric.api import sudo
from fabtools import deb
from fabtools import service
from fabtools.files import watch
from fabtools.supervisor import update_config, process_status, start_process
from fabtools.system import distrib_family
from fabtools.require import python as require_python
from fabtools.require.service import started as require_started
from fabtools.require import file as require_file
from fabtools.require import directory as require_directory
from fabtools.require import user as require_user
from fabtools.files import is_file

from fabric.api import hide, settings
from fabtools.utils import run_as_root


def require_supervisor(requireStarted=True, **kwargs):

    TEMPLATE_DIR = os.path.dirname(os.path.abspath(__file__)) + '/../templates'

    if not deb.is_installed('python-pip'):
        deb.install('python-pip')

    is_installed = require_python.is_installed('supervisor')

    require_python.package('supervisor', use_sudo=True)
    require_python.package('superlance', use_sudo=True)

    if not is_file('/usr/bin/crashmailbatch',use_sudo=True):
        sudo('ln -s /usr/local/bin/crashmailbatch /usr/bin/')

    if not is_file('/usr/bin/fatalmailbatch',use_sudo=True):
        sudo('ln -s /usr/local/bin/fatalmailbatch /usr/bin/')

    require_user('supervisord', create_home=False)
    require_directory('/var/log/supervisord', owner='supervisord', use_sudo=True)
    require_directory('/var/run/supervisord', owner='supervisord', use_sudo=True)
    require_directory('/etc/supervisor.d', owner='supervisord', use_sudo=True)


    require_file('/etc/supervisord.conf', source = TEMPLATE_DIR + '/supervisor/supervisord.conf', owner = 'supervisord', use_sudo=True)
    require_file('/etc/init.d/supervisord', source = TEMPLATE_DIR + '/supervisor/supervisord.init', owner = 'supervisord', mode='770', use_sudo=True)
    require_file('/etc/supervisor.d/supervisord.ini', source = TEMPLATE_DIR + '/supervisor/supervisord.ini', owner = 'supervisord', use_sudo=True)

    if not is_installed:
        #sudo('sudo chmod +x /etc/init.d/supervisord')
        sudo('sudo update-rc.d supervisord defaults')

    is_service_running = False

    with settings(hide('running', 'stdout', 'stderr', 'warnings'), warn_only=True):
        res = run_as_root('service supervisord status')
        is_service_running = res.succeeded


    if requireStarted:
        if not is_service_running:
            service.start('supervisord')


def process(name, requireStarted=True, **kwargs):
    """
    Require a supervisor process to be running.

    Keyword arguments will be used to build the program configuration
    file. Some useful arguments are:

    - ``command``: complete command including arguments (**required**)
    - ``directory``: absolute path to the working directory
    - ``user``: run the process as this user
    - ``stdout_logfile``: absolute path to the log file

    You should refer to the `supervisor documentation`_ for the
    complete list of allowed arguments.

    .. note:: the default values for the following arguments differs from
              the ``supervisor`` defaults:

              - ``autorestart``: defaults to ``true``
              - ``redirect_stderr``: defaults to ``true``

    Example::

        from fabtools import require

        require.supervisor.process('myapp',
            command='/path/to/venv/bin/myapp --config production.ini --someflag',
            directory='/path/to/working/dir',
            user='alice',
            stdout_logfile='/path/to/logs/myapp.log',
            )

    .. _supervisor documentation: http://supervisord.org/configuration.html#program-x-section-values
    """

    require_supervisor(requireStarted=requireStarted)

    # Set default parameters
    params = {}
    params.update(kwargs)
    params.setdefault('autorestart', 'true')
    params.setdefault('redirect_stderr', 'true')

    # Build config file from parameters
    lines = []
    lines.append('[program:%(name)s]' % locals())
    for key, value in sorted(params.items()):
        lines.append("%s=%s" % (key, value))

    filename = '/etc/supervisor.d/%(name)s.ini' % locals()

    with watch(filename, callback=update_config, use_sudo=True):
        require_file(filename, contents='\n'.join(lines), use_sudo=True)


    # Start the process if needed

    if requireStarted and process_status(name) == 'STOPPED':
        start_process(name)

def listener(name, requireStarted=True, **kwargs):
    """
    Require a supervisor event listener .

    """

    require_supervisor(requireStarted=requireStarted)

    # Set default parameters
    params = {}
    params.update(kwargs)
    params.setdefault('events','PROCESS_STATE,TICK_60')
    params.setdefault('user','supervisord')
    params.setdefault('buffer_size','50')

    # Build config file from parameters
    lines = []
    lines.append('[eventlistener:%(name)s]' % locals())
    for key, value in sorted(params.items()):
        lines.append("%s=%s" % (key, value))

    filename = '/etc/supervisor.d/%(name)s.ini' % locals()

    with watch(filename, callback=update_config, use_sudo=True):
        require_file(filename, contents='\n'.join(lines), use_sudo=True)

    # Start the process if needed
    if requireStarted and process_status(name) == 'STOPPED':
        start_process(name)

