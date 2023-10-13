#!/usr/bin/env python
from __future__ import absolute_import


if __name__ == '__main__':
    import os
    import sys

    from webassets import Environment
    from webassets.loaders import PythonLoader
    from webassets.filter import register_filter
    from webassets.script import main

    from castle.common.web.webassets import Underscore

    register_filter(Underscore)

    import castle.web.console.bundles as bundles

    # Setup environment
    env = Environment(
        directory=os.path.dirname(__file__),
        url=None,
        debug=False,
        url_expire=True,
        versions='hash',
        manifest='json:.castle-console.manifest'
    )

    env.config['UNDERSCORE_TPL_SETTINGS'] = '{"variable": "ctx", "interpolate": /\{\{(.+?)\}\}/g, "escape": /\{\{-(.+?)\}\}/g, "evaluate": /\{#(.+?)\}\}/g}'

    env.register(PythonLoader(bundles).load_bundles())

    main(sys.argv[1:], env)
