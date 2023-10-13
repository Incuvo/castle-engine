"""
Stud
=====

The Scalable TLS Unwrapping Daemon

.. Stud: https://github.com/bumptech/stud

"""
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


VERSION = '0.3-dev'

BINARIES = [
    'stud',
]


def installed_from_source(version=VERSION):
    """
    Require Stud to be installed from source.

    The compiled binaries will be installed in ``/opt/stud-{version}/``.
    """
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

    

    require_user('stud', home='/var/lib/stud', system=True)
    require_directory('/var/lib/stud', owner='stud', use_sudo=True)
    require_directory('/etc/stud', owner='stud', use_sudo=True)
    require_directory('/var/lib/stud/ssl', owner='stud', use_sudo=True)


    dest_dir = '/opt/stud-%(version)s' % locals()
    require_directory(dest_dir, use_sudo=True, owner='stud')

    if not is_file('%(dest_dir)s/stud' % locals()):

        with cd('/tmp'):

            # Download and unpack the zip
            zip_filename = 'stud-%(version)s.zip' % locals()
            url = 'https://github.com/bumptech/stud/archive/master.zip'
            require_file(zip_filename, url=url)
            run('unzip -o -q %(zip_filename)s' % locals())

            # Compile and install binaries
            with cd('stud-master'):
                run('make')
                sudo('./stud --ssl --write-proxy -u stud -g stud -b 127.0.0.1,8443 -f *,443 --default-config > /etc/stud/stud.cfg',user='stud')
                append('/etc/stud/stud.cfg','ssl on', use_sudo=True)

                for filename in BINARIES:
                    run_as_root('cp -pf %(filename)s %(dest_dir)s/' % locals())
                    run_as_root('chown stud: %(dest_dir)s/%(filename)s' % locals())



def pem(path, version=VERSION):

    from fabtools.require import file as require_file
    from supervisor import process as require_process

    if isinstance(path, basestring):
        path = [path]

    installed_from_source()

    need_to_be_restarted = False

    for p in path:

        if is_file(p):
            if not contains('/etc/stud/stud.cfg', p, use_sudo=True):
                append('/etc/stud/stud.cfg','pem-file = \"%(p)s\"' % locals(), use_sudo=True)
                need_to_be_restarted = True
        else:
            basename    = os.path.basename(p)
            remote_path = '/var/lib/stud/ssl/%(basename)s' % locals()

            require_file(remote_path, source = p, owner = 'stud', mode='600', use_sudo=True)

            if not contains('/etc/stud/stud.cfg', remote_path, use_sudo=True):
                append('/etc/stud/stud.cfg','pem-file = \"%(remote_path)s\"' % locals(), use_sudo=True)
                need_to_be_restarted = True



    if not is_file('/etc/supervisor.d/stud.ini'):
        require_process(
            'stud',
            user='root',
            command="/opt/stud-%(version)s/stud --config=/etc/stud/stud.cfg" % locals(),
            autostart='true', 
            autorestart='true',
            priority=998,
    )
    elif need_to_be_restarted:
            fabtools.supervisor.restart_process('stud')
