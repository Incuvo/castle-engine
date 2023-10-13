import os
import time
import posixpath
import fabric

from tools import nodejs
from tools import redis
from tools import stud
from tools import supervisor
from tools import utils
from tools import haproxy

from fabtools.files import is_file, watch
from fabric.api import *
from fabric.contrib.files import append
from fabtools.supervisor import process_status
from fabtools import python
from fabtools import require
from fabtools import deb
from fabtools.files import is_file
from fabtools.files import is_dir
from fabtools.deb import install
from fabtools.deb import is_installed
from fabtools import service
from fabtools.require import directory as require_directory
from fabtools.require import file as require_file
from fabric.api import cd
from fabtools.python import virtualenv
from fabric.contrib.files import append
from fabtools.vagrant import vagrant


CASTLE_VIRTUALENV_ROOT='/home/castle/env/castle.com'

TEMPLATE_DIR = os.path.dirname(os.path.abspath(__file__)) + '/templates'

def generate_local_deploy_ssh_keys():

    if not fabric.contrib.files.exists('~/.ssh/local_deploy.pub'):
        run("ssh-keygen -q -t rsa -f ~/.ssh/local_deploy -N ''")
        run('echo -n from=\\""127.0.0.1,::1\\""\  | cat - ~/.ssh/local_deploy.pub >> ~/.ssh/authorized_keys')

def update_castle_src():

    require.user('castle')

    if not is_installed('git-core'):
        install('git-core')

    #setup git access ssh keys
    if not is_dir('/home/castle/.ssh',use_sudo=True):
        sudo('mkdir /home/castle/.ssh') 
        sudo('chmod 700 /home/castle/.ssh')
        sudo('chown castle:castle /home/castle/.ssh')

    if not is_file('/home/castle/.ssh/bitbucket.org',use_sudo=True):
        put('deploy_keys/config','/home/castle/.ssh/config', use_sudo=True)
        put('deploy_keys/bitbucket.org','/home/castle/.ssh/bitbucket.org',use_sudo=True)
        sudo('chown castle:castle /home/castle/.ssh/config')
        sudo('chown castle:castle /home/castle/.ssh/bitbucket.org')
        sudo('chmod 600 /home/castle/.ssh/config')
        sudo('chmod 600 /home/castle/.ssh/bitbucket.org')

    #pull latest master branch
    with settings(sudo_user='castle'):
        if not is_file('/home/castle/src/README.md',use_sudo=True):
            sudo('cd ~ && git clone ssh://git@bitbucket.org/castle/backend.git src')
        else:
            sudo('cd ~/src && git pull')

    

def setup(updateSource=True):


    #ensure that castle account exists
    require.user('castle')

    if updateSource:
        update_castle_src()

    #setup ssh keys for self deploment
    generate_local_deploy_ssh_keys()


    if not is_installed('python-pip'):
        install('python-pip')

    if nodejs.version() == None:
        nodejs.install_from_source()


    if not python.is_installed('fabtools'):
        require.python.package('git+git://github.com/ronnix/fabtools.git', use_sudo=True)

    require.python.package('apache-libcloud', use_sudo=True)
    
   
    if not is_file(posixpath.join(CASTLE_VIRTUALENV_ROOT, 'bin', 'python')):

        require.python.virtualenv(CASTLE_VIRTUALENV_ROOT, user='castle', use_sudo=True)

        append('/home/castle/env/castle.com/bin/activate', 'export NODE_PATH=/usr/lib/nodejs:/usr/share/javascript:/usr/local/lib/node_modules:/home/castle/node_modules', use_sudo=True)
        append('/home/castle/env/castle.com/bin/activate', 'export PYTHONPATH=/home/castle/src:$PYTHONPATH', use_sudo=True)


    with settings(sudo_user='castle'):
        with virtualenv(CASTLE_VIRTUALENV_ROOT):
            require.python.package('boto', use_sudo=True)
            require.python.package('apache-libcloud', use_sudo=True)
            require.python.package('setproctitle', use_sudo=True)


        with cd('/home/castle'):

            nodejs.require_packages([
                { 'name':'coffee-script','version':'1.4.0' },
                { 'name':'mubsub'},
                { 'name':'fbgraph'      },
                { 'name':'hashids'      },
                { 'name':'elastical'    },
                { 'name':'natural'      },
                { 'name':'meld'         },
                { 'name':'moment'       },
                { 'name':'measured'     },
                { 'name':'less',  'version':'1.3.3' },
                { 'name':'connect'  },
                { 'name':'express','version':'3.1.0'},
                { 'name':'jade'   ,'version':'0.28.1'},
                { 'name':'request'  },
                { 'name':'hiredis'  },
                { 'name':'redis'    },
                { 'name':'mongodb', 'param':'--mongodb:native' },
                #{ 'name':'node-gearman' },
                { 'name':'awssum', 'version':'0.12.2' },
                { 'name':'mongoose','version':'3.5.6'},
                { 'name':'client-sessions' },
                { 'name':'bcrypt' },
                { 'name':'underscore' },
                { 'name':'underscore.string' },
                { 'name':'async' },
                { 'name':'xml2js', 'version':'0.4.1'},
                { 'name':'node-schedule', 'version':'0.1.13'},
                { 'name':'http-proxy', 'version':'0.10.4'},
                { 'name':'node-schedule', 'version':'0.1.13'},
                { 'name':'locksmith', 'version':'0.0.1'},
                { 'name':'xregexp'},
                { 'name':'validator', 'version':'3.30.0'},
                { 'name':'in-app-purchase', 'version':'0.4.5'},

                #{ 'name':'csv' },
                #{ 'name':'mocha' },
                #{ 'name':'zombie' },
                #{ 'name':'should' },
            ],local=True, use_sudo=True)


    require_directory('/var/log/castle', use_sudo=True, owner='castle')
    require_directory('/var/run/castle', use_sudo=True, owner='castle')


    if not is_file('/home/castle/env/castle.com/bin/coffee',use_sudo=True):
        sudo('ln -s /home/castle/node_modules/coffee-script/bin/coffee /home/castle/env/castle.com/bin/')
        sudo('ln -s /home/castle/node_modules/less/bin/lessc /home/castle/env/castle.com/bin/')


    require_file('/usr/sbin/castle',            source = TEMPLATE_DIR + '/castle/bin/castle',     mode='770', owner = 'castle', use_sudo=True)
    require_file('/etc/default/castle',         source = TEMPLATE_DIR + '/castle/castle.default', mode='660', owner = 'castle', use_sudo=True)
    require_file('/etc/default/castle-api',     source = TEMPLATE_DIR + '/castle/api.default',        mode='660', owner = 'castle', use_sudo=True)
    require_file('/etc/default/castle-queue',   source = TEMPLATE_DIR + '/castle/queue.default',      mode='660', owner = 'castle', use_sudo=True)
    require_file('/etc/default/castle-console', source = TEMPLATE_DIR + '/castle/console.default',    mode='660', owner = 'castle', use_sudo=True)


