import castle
from fabtools.vagrant import vagrant

from fabric.api import *

if  env.user is None:
    env.user = os.getenv('USER','ubuntu')

env['sudo_prefix'] += '-H '


@task
def update_castle_src():
    castle.update_castle_src()