import os
import time
import posixpath
import config
import tools

from tools import nodejs
from tools import redis
from tools import stud
from tools import supervisor
from tools import utils
from tools import haproxy

import castle

from fabric.api import *
from fabric.contrib.files import append
from fabtools.supervisor import process_status
from fabtools.supervisor import restart_process
from fabtools.files import watch
from fabtools import python
from fabtools import require
from fabtools import deb
from fabtools.files import is_file
from fabtools.files import is_dir
from fabtools.deb import install
from fabtools.deb import is_installed
from fabtools import service
from fabtools.require import directory as require_directory
from fabric.api import cd
from fabtools.python import virtualenv
from fabric.contrib.files import append
from fabtools.vagrant import vagrant
from fabtools.require import file as require_file


from aws import create_ami
from aws import launch_castle_api_instance
from aws import update_castle_api_instance
from aws import restart_castle_api_instance
from aws import show_logs_castle_api_instance


TEMPLATE_DIR = os.path.dirname(os.path.abspath(__file__)) + '/templates'

if  env.user is None:
    env.user = os.getenv('USER','ubuntu')



env['sudo_prefix'] += '-H '


@task
def update_castle_src():
    castle.update_castle_src()


@task
def build():
    env.user='castle'
    with virtualenv('/home/castle/env/castle.com'):
        run('./src/castle/web/console/assets.py build')

@task
def pull():
    env.user='castle'
    with cd('./src'):
        run('git pull')

@task
def status():
    print process_status('')
    #sudo('supervisorctl status')

@task
def restart_api():
    sudo('supervisorctl restart castle:castle-api')

@task

def restart_console():
    sudo('supervisorctl restart castle:castle-console')


@task
def makesudo():
    env.user='ice-k'
    require.users.sudoer('ice-k')



@task
def install_or_castle_console():

    #sudo('apt-get update')
    #sudo('apt-get upgrade --assume-yes')

    #install_haproxy()
    #install_stud()
    install_or_update_castle_console()


@task
def install_mongodb_redis_castle_api():

    install_mongodb()
    install_redis()
    install_or_update_castle_api()

@task
def install_or_update_redis_and_castle_api_autoboot_update():

    sudo('apt-get update')
    sudo('apt-get upgrade --assume-yes')

    install_redis()
    install_or_update_castle_api()
    install_autoboot_update()


@task
def install_or_update_castle_api_autoboot_update():

    sudo('apt-get update')
    sudo('apt-get upgrade --assume-yes')

    install_or_update_castle_api()
    install_autoboot_update()


@task
def install_mongodb_redis():

    sudo('apt-get update')
    sudo('apt-get upgrade --assume-yes')

    install_mongodb()
    install_redis()


@task
def install_mongodb():

    #sudo('apt-get install lvm2 --assume-yes')
    #sudo('apt-get install mdadm --assume-yes')

    if not deb.is_installed('mongodb-10gen'):
        sudo('apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10')
        require.deb.source('mongodb', 'http://downloads-distro.mongodb.org/repo/ubuntu-upstart', 'dist', '10gen')
        sudo('apt-get install mongodb-10gen')
        sudo('sudo service mongodb stop')

        while utils.is_mongodb_service_running():
            time.sleep(200)

        sudo('update-rc.d -f mongodb remove')
        sudo("sh -c \"echo 'manual' > /etc/init/mongodb.override\"")

    supervisor.process('mongodb',command='/usr/bin/mongod --config /etc/mongodb.conf', user='mongodb', priority=995)



@task
def install_haproxy():
    haproxy.installed_from_source()

@task
def install_stud():

    stud.pem([
        "certs/api.castle.com.pem",
        "certs/console.castle.com.pem"
    ])

@task
def install_redis():
    redis.instance('castle-db0', port='6379', daemonize='no',bind = '0.0.0.0')



@task
def show_logs_castle_api():
    sudo('tail -n 50 /var/log/castle/api.stdout.log')
    sudo('tail -n 50 /var/log/castle/api.stderr.log')



@task
def update_and_restart_castle_api(restart=False, updateSource=True, requireStarted=True):

    install_or_update_castle_api(True, updateSource, requireStarted)

@task
def install_or_update_castle_api(restart=False, updateSource=True, requireStarted=True):


    restart        = utils.booleanize(restart)
    updateSource   = utils.booleanize(updateSource)
    requireStarted = utils.booleanize(requireStarted)

    with watch(['/usr/sbin/castle','/etc/default/castle','/etc/default/castle-api'], use_sudo=True) as castle_config:
        castle.setup(updateSource=updateSource)
    
    #castle_config.changed

    supervisor.process('castle-api',requireStarted=requireStarted,
                                command='castle api', 
                                user='castle', 
                                autostart='true', 
                                autorestart='true', 
                                redirect_stderr='false',
                                stdout_logfile='/var/log/castle/api.stdout.log',
                                stderr_logfile='/var/log/castle/api.stderr.log')


    if restart:
        restart_process('castle-api')

@task
def install_or_update_castle_console(restart=False, updateSource=True, requireStarted=True):

    restart        = utils.booleanize(restart)
    updateSource   = utils.booleanize(updateSource)
    requireStarted = utils.booleanize(requireStarted)

    from fabtools.require.deb import packages as require_deb_packages

    require_deb_packages([
        'openjdk-6-jre'
    ])

    with watch(['/usr/sbin/castle','/etc/default/castle','/etc/default/castle-console'], use_sudo=True) as castle_config:
        castle.setup(updateSource=updateSource)

    with settings(sudo_user='castle'):
        with virtualenv(castle.CASTLE_VIRTUALENV_ROOT):
            require.python.package('webassets==0.8', use_sudo=True)
            require.python.package('yuicompressor', use_sudo=True)

            with cd('/home/castle'):
                 sudo('./src/castle/web/console/assets.py build')

    supervisor.process('castle-console',requireStarted=requireStarted,
                                command='castle console', 
                                user='castle', 
                                autostart='true', 
                                autorestart='true', 
                                redirect_stderr='false',
                                stdout_logfile='/var/log/castle/console.stdout.log',
                                stderr_logfile='/var/log/castle/console.stderr.log')




    if restart:
        restart_process('castle-console')


@task
def install_or_update_castle_controller(restart=False, updateSource=True, requireStarted=True):

    restart        = utils.booleanize(restart)
    updateSource   = utils.booleanize(updateSource)
    requireStarted = utils.booleanize(requireStarted)

    from fabtools.require.deb import packages as require_deb_packages

    require_deb_packages([
        'openjdk-6-jre'
    ])

    with watch(['/usr/sbin/castle','/etc/default/castle','/etc/default/castle-controller'], use_sudo=True) as castle_config:
        castle.setup(updateSource=updateSource)

    with settings(sudo_user='castle'):
        with virtualenv(castle.CASTLE_VIRTUALENV_ROOT):
            require.python.package('webassets==0.8', use_sudo=True)
            require.python.package('yuicompressor', use_sudo=True)

            with cd('/home/castle'):
                 sudo('./src/castle/web/controller/assets.py build')

    require_file('/etc/default/castle-controller', source = TEMPLATE_DIR + '/castle/controller.default', mode='660', owner = 'castle', use_sudo=True)

    supervisor.process('castle-controller',requireStarted=requireStarted,
                                command='castle controller', 
                                user='castle', 
                                autostart='true', 
                                autorestart='true', 
                                redirect_stderr='false',
                                stdout_logfile='/var/log/castle/controller.stdout.log',
                                stderr_logfile='/var/log/castle/controller.stderr.log')




    if restart:
        restart_process('castle-controller')


@task
def install_or_update_monitor(restart=False, updateSource=True, requireStarted=True):

    restart        = utils.booleanize(restart)
    updateSource   = utils.booleanize(updateSource)
    requireStarted = utils.booleanize(requireStarted)

    from fabtools.require.deb import packages as require_deb_packages

    with settings(sudo_user='castle'):
        with virtualenv(castle.CASTLE_VIRTUALENV_ROOT):
            require.python.package('boto', use_sudo=True)
            require.python.package('bson', use_sudo=True)
            require.python.package('pymongo', use_sudo=True)
            require.python.package('flask', use_sudo=True)
            require.python.package('flask-auth', use_sudo=True)
            require.python.package('simplejson', use_sudo=True)

    require_file('/etc/default/castle-monitor', source = TEMPLATE_DIR + '/castle/monitor.default', mode='660', owner = 'castle', use_sudo=True)

    supervisor.process('castle-monitor',requireStarted=requireStarted,
                                command='castle monitor', 
                                user='castle', 
                                autostart='true', 
                                autorestart='true', 
                                redirect_stderr='false',
                                stdout_logfile='/var/log/castle/monitor.stdout.log',
                                stderr_logfile='/var/log/castle/monitor.stderr.log')




    if restart:
        restart_process('castle-monitor')


@task
def install_autoboot_update():
    require_file('/etc/default/castle_api_update', contents='CASTLE_UPDATE_USER=%s\n' % ( run('echo $USER') ), mode='660', owner = 'castle', use_sudo=True)
    require_file('/etc/init.d/castle_api_update',  source = TEMPLATE_DIR + '/castle/castle_api_update.init', mode='770', owner = 'castle', use_sudo=True)
    sudo('sudo update-rc.d castle_api_update defaults 10')


@task
def install_diskspace_and_memory_metrics(namespace='System/Linux'):
        user = run('echo $USER')
        require_file('/usr/sbin/send_disk_space_and_memory_metrics',source = TEMPLATE_DIR + '/send_disk_space_and_memory_metrics.sh',mode='770', owner = user, use_sudo=True)

        timespec = '*/5 * * * *'
        command  = '/usr/sbin/send_disk_space_and_memory_metrics "' + namespace + '"'

        require_file('/etc/cron.d/aws_metrics', contents='%(timespec)s root %(command)s\n' % locals(), mode='600', owner = 'root', use_sudo=True)
