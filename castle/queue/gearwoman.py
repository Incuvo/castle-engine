from __future__ import absolute_import

import importlib
import json
import logging
import multiprocessing as mp
import Queue as queue
import pkgutil
import setproctitle
import signal
import time

import gearman

import castle.common.retro as retro


class JSONDataEncoder(gearman.DataEncoder):
    @classmethod
    def encode(cls, encodable_object):
        return json.dumps(encodable_object)

    @classmethod
    def decode(cls, decodable_string):
        return json.loads(decodable_string)


class JSONWorker(gearman.GearmanWorker):
    data_encoder = JSONDataEncoder

    def after_poll(self, any_activity):
        continue_working = True
        # Do something after every select loop
        return continue_working


class UnexpectedFinish(Exception):
    def __init__(self, worker_client_id):
        self.worker_client_id = worker_client_id


class Task(object):
    DEFAULT_NAME = None

    def __init__(self, name=None, config=None, logger=None):
        self.name = name if name is not None else self.DEFAULT_NAME
        self.config = config
        self.logger = logger

    def __call__(self, worker, job):
        try:
            return self.run(worker, job)
        except Exception as e:
            self.logger.error(
                '[{}] An error occured whilst running "{}" task. [{}] {}'.format(
                    worker.worker_client_id, self.name, e.__class__.__name__, str(e)
                )
            )
            # Disconnect so this job goes back into the queue
            worker.shutdown()

    def run(self, worker, job):
        pass


class GearmanWorkerServer(object):
    def __init__(self, hosts, worker_class=None, id_prefix=None,
            max_workers=None, logger=None, config=None,
            process_name='Gearman Worker Server'):
        self.hosts = hosts
        self.worker_class = (
            worker_class
            if worker_class is not None
            else JSONWorker
        )
        self.id_prefix = (
            id_prefix
            if id_prefix is not None
            else 'gearman_worker'
        )
        self.max_workers = (
            max_workers
            if max_workers is not None
            else mp.cpu_count()
        )
        self.logger = logger if logger is not None else logging.getLogger()
        self.config = config
        self.process_name = process_name
        self.tasks = []

        self._setup_sighandlers()

    def load_tasks(self, paths):
        if isinstance(paths, str):
            paths = [paths]

        for path in paths:
            if isinstance(path, str):
                segments = path.split('.')

                if len(segments) > 0 and segments[-1][0].isupper():
                    package = '.'.join(segments[:-1])
                    class_name = segments[-1]

                    module = importlib.import_module(package)

                else:
                    root_module = importlib.import_module(path)

                    modules = [
                        importlib.import_module('{}.{}'.format(root_module.__name__, name))
                        for loader, name, ispkg in pkgutil.walk_packages(root_module.__path__)
                        if not ispkg
                    ]

                    modules.append(root_module)

                    self.tasks.extend([
                        task_class(config=self.config, logger=self.logger)
                        for m in modules
                        for task_class in retro.getsubclasses(m, Task)
                        if task_class.DEFAULT_NAME != None
                    ])

                    self.logger.info('[main] Loaded {} task(s) '.format(len(self.tasks)))
            elif isinstance(path, Task):
                self.tasks.append(path)
            else:
                self.logger.warning('[main] Unrecognized path: {}'.format(str(path)))

    def serve_forever(self):
        setproctitle.setproctitle(self.process_name)

        process_counter = 0
        workers = []

        self._error_queue = mp.Queue()

        try:
            while True:
                while len(workers) < self.max_workers:
                    process_counter += 1
                    client_id = '{}_{}'.format(self.id_prefix, process_counter)

                    p = mp.Process(target=self._worker_process, args=(client_id,))

                    self.logger.info('[main] Starting worker process #{}'.format(process_counter))

                    p.start()
                    workers.append(p)

                try:
                    e = self._error_queue.get()
                except queue.Empty:
                    e = None

                if e is not None:
                    if isinstance(e, gearman.errors.ServerUnavailable):
                        self.logger.warning('[main] Gearman server is unavailable. Reconnecting...')
                        time.sleep(2)

                    elif isinstance(e, UnexpectedFinish):
                        self.logger.warning(
                            '[main] Gearman worker "{}" finished unexpectedly'.format(e.worker_client_id)
                        )
                    else:
                        self.logger.error(
                            '[main] Unexpected error {}: {}'.format(e.__class__.__name__, str(e))
                        )

                time.sleep(0.1)

                workers = [
                    w
                    for w in mp.active_children()
                    if w in workers
                ]
        except KeyboardInterrupt:
            self.logger.error('[main] Received interrupt. Exiting...')

    def _worker_process(self, client_id):
        setproctitle.setproctitle('Worker {}'.format(client_id))

        try:
            worker = self.worker_class(host_list=self.hosts)
            worker.set_client_id(client_id)

            for task in self.tasks:
                self.logger.debug('[{}] Registering task {}'.format(client_id, task.name))
                worker.register_task(task.name, task)

            self.logger.info('[{}] Going to work...I hate Mondays.'.format(client_id))

            worker.work()
        except gearman.errors.ServerUnavailable as e:
            self._error_queue.put(e)
            return
        except KeyboardInterrupt:
            #Prevents child process from printing traceback
            return

        self._error_queue.put(UnexpectedFinish(client_id))

    def _setup_sighandlers(self):
        signal.signal(signal.SIGINT,  self._interrupt_handler)
        signal.signal(signal.SIGTERM, self._interrupt_handler)

    def _interrupt_handler(self, signum, frame):
        '''
        Python maps SIGINT to KeyboardInterrupt by default, but we need to
        catch SIGTERM as well, so we can give jobs as much of a chance as
        possible to alert the gearman server to requeue the job.
        '''
        raise KeyboardInterrupt()
