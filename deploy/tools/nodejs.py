"""
Node.js
=======

This module provides tools for installing `Node.js`_ and managing
packages using `npm`_.

.. note: the ``simplejson`` module is required on Python 2.5

.. _Node.js: http://nodejs.org/
.. _npm: http://npmjs.org/

"""
from __future__ import with_statement

try:
    import json
except ImportError:
    import simplejson as json

from fabric.api import sudo, cd, hide, run, settings

from fabtools.system import cpus, distrib_family
from fabtools.utils import run_as_root


DEFAULT_VERSION = '0.10.4'


def install_from_source(version=DEFAULT_VERSION):
    """
    Install Node JS from source.

    ::

        import fabtools

        # Install Node.js
        fabtools.nodejs.install_nodejs()

    .. note:: This function may not work for old versions of Node.js.

    """

    from fabtools.require.deb import packages as require_deb_packages
    from fabtools.require.rpm import packages as require_rpm_packages
    from fabtools.require import file as require_file

    family = distrib_family()

    if family == 'debian':
        require_deb_packages([
            'build-essential',
            'libssl-dev',
            'python',
        ])

    elif family == 'redhat':
        require_rpm_packages([
            'gcc',
            'gcc-c++',
            'make',
            'openssl-devel',
            'python',
        ])

    filename = 'node-v%s.tar.gz' % version
    foldername = filename[0:-7]

    require_file(url='http://nodejs.org/dist/v%(version)s/%(filename)s' % {
        'version': version,
        'filename': filename,
    })
    run('tar -xzf %s' % filename)
    with cd(foldername):
        run('./configure')
        run('make -j%d' % (cpus() + 1))
        run_as_root('make install')
    run('rm -rf %(filename)s %(foldername)s' % locals())


def version():
    """
    Get the version of Node.js currently installed.

    Returns ``None`` if it is not installed.
    """
    with settings(hide('running', 'stdout', 'warnings'), warn_only=True):
        res = run('/usr/local/bin/node --version')
    if res.failed:
        return None
    else:
        return res[1:]


def install_package(package, version=None, local=False, use_sudo=False):
    """
    Install a Node.js package.

    If *local* is ``True``, the package will be installed locally.

    ::

        import fabtools

        # Install package globally
        fabtools.nodejs.install_package('express')

        # Install package locally
        fabtools.nodejs.install_package('underscore', local=False)

    """
    if version:
        package += '@%s' % version

    if local:
        if use_sudo:
            sudo('/usr/local/bin/npm install -l %s' % package)
        else:
            run('/usr/local/bin/npm install -l %s' % package)
    else:
        run_as_root('HOME=/root /usr/local/bin/npm install -g %s' % package)


def install_dependencies():
    """
    Install Node.js package dependencies.

    This function calls ``npm install``, which will locally install all
    packages specified as dependencies in the ``package.json`` file
    found in the current directory.

    ::

        from fabric.api import cd
        from fabtools import nodejs

        with cd('/path/to/nodejsapp/'):
            nodejs.install_dependencies()

    """
    run('/usr/local/bin/npm install')


def package_version(package, local=False,use_sudo = False):
    """
    Get the installed version of a Node.js package.

    Returns ``None``is the package is not installed. If *local* is
    ``True``, returns the version of the locally installed package.
    """
    options = ['--json true', '--silent']
    if local:
        options.append('-l')
    else:
        options.append('-g')
    options = ' '.join(options)

    with hide('running', 'stdout'):
        if use_sudo:
            res = sudo('/usr/local/bin/npm list %s' % options)
        else:
            res = run('/usr/local/bin/npm list %s' % options)

    dependencies = json.loads(res)['dependencies']
    pkg_data = dependencies.get(package)
    if pkg_data:
        return pkg_data['version']
    else:
        return None


def update_package(package, local=False, use_sudo = False):
    """
    Update a Node.js package.

    If *local* is ``True``, the package will be updated locally.
    """
    if local:
        if use_sudo:
            run('/usr/local/bin/npm update -l %s' % package)
        else:
            sudo('/usr/local/bin/npm update -l %s' % package)
    else:
        run_as_root('HOME=/root /usr/local/bin/npm update -g %s' % package)


def uninstall_package(package, version=None, local=False, use_sudo = False):
    """
    Uninstall a Node.js package.

    If *local* is ``True``, the package will be uninstalled locally.

    ::

        import fabtools

        # Uninstall package globally
        fabtools.nodejs.uninstall_package('express')

        # Uninstall package locally
        fabtools.nodejs.uninstall_package('underscore', local=False)

    """
    if version:
        package += '@%s' % version

    if local:
        if use_sudo:
            sudo('/usr/local/bin/npm uninstall -l %s' % package)
        else:
            run('/usr/local/bin/npm uninstall -l %s' % package)
    else:
        run_as_root('HOME=/root /usr/local/bin/npm uninstall -g %s' % package)

def installed_from_source(version=DEFAULT_VERSION):
    """
    Require Node.js to be installed from source.

    ::

        from fabtools import require

        require.nodejs.installed_from_source()

    """
    if version() != version:
        install_from_source(version)



def require_package(pkg_name, param = '', version=None, local=False,use_sudo=False):
    """
    Require a Node.js package.

    If the package is not installed, and no *version* is specified, the
    latest available version will be installed.

    If a *version* is specified, and a different version of the package
    is already installed, it will be updated to the specified version.

    If `local` is ``True``, the package will be installed locally.

    ::

        from fabtools import require

        # Install package system-wide
        require.nodejs.package('foo')

        # Install package locally
        require.nodejs.package('bar', local=True)

    """

    pkg_version = package_version(pkg_name, local=local, use_sudo=use_sudo)
    if version:
        if pkg_version != version:
            install_package(pkg_name, version, local=local, use_sudo=use_sudo)
    else:
        if pkg_version is None:
            install_package(pkg_name + ' ' + param, local=local, use_sudo=use_sudo)


def require_packages(packages, local=False,use_sudo=False):
    """
    Require a Node.js packages.
    """
    if isinstance(packages, basestring):
        packages = [{'name' : packages }]


    options = ['--json true', '--silent']

    if local:
        options.append('-l')
    else:
        options.append('-g')

    options = ' '.join(options)

    with hide('running', 'stdout'):
        if use_sudo:
            res = sudo('/usr/local/bin/npm list %s' % options)
        else:
            res = run('/usr/local/bin/npm list %s' % options)

    dependencies = json.loads(res)['dependencies']


    for package in packages:

        name = package.get('name',None)

        if not name:
            continue

        param            = package.get('param','')
        required_version = package.get('version',None)
        current_version  = None

        pkg_data = dependencies.get(name)

        if pkg_data:
            current_version =  pkg_data['version']

        if required_version:
            if current_version != required_version:
                install_package(name, required_version, local=local, use_sudo=use_sudo)
        else:
            if current_version is None:
                install_package(name + ' ' + param, local=local, use_sudo=use_sudo)
