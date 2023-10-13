from __future__ import with_statement

import supervisor
from fabric.api import cd, run, settings

from fabtools.files import is_file, watch
from fabtools.system import distrib_family
from fabtools.utils import run_as_root
import fabtools.supervisor
from fabtools import require


VERSION = '2.6.12'

BINARIES = [
    'redis-benchmark',
    'redis-check-aof',
    'redis-check-dump',
    'redis-cli',
    'redis-sentinel',
    'redis-server',
]

def instance(name, version=VERSION, **kwargs):
    """
    Require a Redis instance to be running.

    The instance will be managed using supervisord, as a process named
    ``redis_{name}``, running as the ``redis`` user.

    ::

        from fabtools import require
        from fabtools.supervisor import process_status

        require.redis.installed_from_source()

        require.redis.instance('db1', port='6379')
        require.redis.instance('db2', port='6380')

        print process_status('redis_db1')
        print process_status('redis_db2')

    .. seealso:: :ref:`supervisor_module` and
                 :ref:`require_supervisor_module`


    """
    from fabtools.require import directory as require_directory
    from fabtools.require import file as require_file
    from fabtools.require.system import sysctl as require_sysctl

    require.redis.installed_from_source(version)

    require_directory('/etc/redis', use_sudo=True, owner='redis')
    require_directory('/var/db/redis', use_sudo=True, owner='redis')
    require_directory('/var/log/redis', use_sudo=True, owner='redis')
    require_directory('/var/run/redis', use_sudo=True, owner='redis')

    # Required for background saving
    with settings(warn_only=True):
        require_sysctl('vm.overcommit_memory', '1')

    # Set default parameters
    params = {}
    params.update(kwargs)
    params.setdefault('bind', '127.0.0.1')
    params.setdefault('port', '6379')
    params.setdefault('pidfile', '/var/run/redis.pid')
    params.setdefault('logfile', '/var/log/redis/redis-%(name)s.log' % locals())
    params.setdefault('loglevel', 'notice')
    params.setdefault('dbfilename', '/var/db/redis/redis-%(name)s-dump.rdb' % locals())
    params.setdefault('save', ['900 1', '300 10', '60 10000'])
    params.setdefault('stop-writes-on-bgsave-error', 'yes')
    params.setdefault('rdbcompression', 'yes')
    params.setdefault('rdbchecksum', 'yes')
    params.setdefault('dir', '/var/lib/redis')

    # Build config file from parameters
    # (keys such as 'save' may result in multiple config lines)
    lines = []
    for key, value in sorted(params.items()):
        if isinstance(value, list):
            for elem in value:
                lines.append("%s %s" % (key, elem))
        else:
            lines.append("%s %s" % (key, value))

    redis_server = '/opt/redis-%(version)s/redis-server' % locals()
    config_filename = '/etc/redis/%(name)s.conf' % locals()

    # Upload config file
    with watch(config_filename, use_sudo=True) as config:
        require_file(config_filename, contents='\n'.join(lines),
                     use_sudo=True, owner='redis')

    # Use supervisord to manage process
    process_name = 'redis_%s' % name
    supervisor.process(
        process_name,
        user='redis',
        command="%(redis_server)s %(config_filename)s" % locals(),
        priority=996,
    )

    # Restart if needed
    if config.changed:
        fabtools.supervisor.restart_process(process_name)
