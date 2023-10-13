from __future__ import with_statement

import os

from fabric.api import cd, run,sudo,settings,put
from fabtools.files import is_file, watch
from fabtools.system import distrib_family
from fabtools.utils import run_as_root
import fabtools.supervisor
from fabric.contrib.files import append
from fabric.contrib.files import contains
from fabtools.supervisor import process_status


VERSION = '1.5-dev18'

BINARIES = [
    'haproxy',
]


def installed_from_source(version=VERSION):

    TEMPLATE_DIR = os.path.dirname(os.path.abspath(__file__)) + '/../templates'

    from fabtools.require import directory as require_directory
    from fabtools.require import file as require_file
    from fabtools.require import user as require_user
    from fabtools.require.deb import packages as require_deb_packages
    from fabtools.require.rpm import packages as require_rpm_packages
    from supervisor import process as require_process

    family = distrib_family()


    if family == 'debian':
        require_deb_packages([
            'build-essential','unzip','libev-dev','libssl-dev'
        ])

    elif family == 'redhat':
        require_rpm_packages([
            'gcc',
            'make',
            'unzip',
            'libev-dev','libssl-dev'
        ])

    

    require_user('haproxy', create_home=False)
    require_directory('/etc/haproxy', owner='haproxy', use_sudo=True)
    require_directory('/etc/haproxy/errorfiles', owner='haproxy', use_sudo=True)
    require_directory('/var/log/haproxy', owner='haproxy', use_sudo=True)

    if not is_file('/usr/local/sbin/haproxy' % locals()):

        with cd('/tmp'):

            # Download and unpack the zip
            tarbar = 'haproxy-%(version)s.tar.gz' % locals()
            url = 'http://haproxy.1wt.eu/download/1.5/src/devel/haproxy-%(version)s.tar.gz' % locals()
            require_file(tarbar, url=url)
            run('tar xzf %(tarbar)s' % locals())

            # Compile and install binaries
            with cd('haproxy-%(version)s' % locals()):
                run('make TARGET=linux26 USE_ZLIB=yes')
                sudo('make install')


    require_file('/etc/haproxy/haproxy.cfg', source = TEMPLATE_DIR + '/haproxy/haproxy.cfg', owner = 'haproxy', use_sudo=True)
    require_file('/etc/haproxy/errorfiles/502.http.api', source = TEMPLATE_DIR + '/haproxy/errorfiles/502.http.api', owner = 'haproxy', use_sudo=True)
    require_file('/etc/haproxy/errorfiles/503.http.api', source = TEMPLATE_DIR + '/haproxy/errorfiles/503.http.api', owner = 'haproxy', use_sudo=True)
    require_file('/etc/haproxy/errorfiles/504.http.api', source = TEMPLATE_DIR + '/haproxy/errorfiles/504.http.api', owner = 'haproxy', use_sudo=True)
    require_file('/etc/haproxy/errorfiles/502.http.console', source = TEMPLATE_DIR + '/haproxy/errorfiles/502.http.console', owner = 'haproxy', use_sudo=True)
    require_file('/etc/haproxy/errorfiles/503.http.console', source = TEMPLATE_DIR + '/haproxy/errorfiles/503.http.console', owner = 'haproxy', use_sudo=True)
    require_file('/etc/haproxy/errorfiles/504.http.console', source = TEMPLATE_DIR + '/haproxy/errorfiles/504.http.console', owner = 'haproxy', use_sudo=True)

    require_process(
            'haproxy',
            user='root',
            command="/usr/local/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid" % locals(),
            autostart='true', 
            autorestart='true',
            priority=998,
            stdout_logfile='/var/log/haproxy/haproxy.stdout.log',
            stderr_logfile='/var/log/haproxy/haproxy.stderr.log')

