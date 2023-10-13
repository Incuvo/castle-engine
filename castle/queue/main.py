#!/usr/bin/env python
from __future__ import absolute_import

import logging
import os

import castle.queue.gearwoman as gearwoman
import castle.queue.config as queue_config


if __name__ == '__main__':
    console = logging.StreamHandler()
    logger = logging.getLogger('castle.queue')
    logger.setLevel(logging.INFO)
    logger.addHandler(console)

    env = os.environ.get('GEARMAN_ENV', 'development')
    settings = getattr(queue_config, env)()

    server = gearwoman.GearmanWorkerServer(
        config={'services': settings['services'], 'castle': settings['castle']},
        logger=logger, **settings['gearman']
    )
    server.load_tasks('castle.queue.tasks')
    server.serve_forever()
