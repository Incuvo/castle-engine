from __future__ import absolute_import

import datetime as dt
import os
import tempfile
import time

from PIL import Image
from boto.s3.connection import S3Connection
from boto.s3.key import Key as S3Key

from castle.queue.gearwoman import Task


class GenerateImageSetTask(Task):
    DEFAULT_NAME = 'generate_image_set'
    SIZES = [170, 96, 48]
    DEFAULT_FORMAT = 'JPEG'
    FORMATS = {
        'JPEG': {
            'ext': 'jpg',
            'mime': 'image/jpeg',
            'options': {
                'quality': 80,
                'optimize': True,
            },
        },
        'PNG': {
            'ext': 'png',
            'mime': 'image/png',
            'options': {},
        }
    }

    def run(self, worker, job):
        start = time.time()

        bucket_name = job.data['bucket']
        path = job.data['path']
        filename = job.data['filename']
        sizes = job.data.get('sizes', self.SIZES)
        fmt = job.data.get('format', self.DEFAULT_FORMAT)

        if fmt not in self.FORMATS:
            self.logger.error(
                '[{}] Failed to create thumbnails for <bucket:{}>, <path:{}> and <sizes:{}>. Unsupported format: {}'.format(
                    worker.worker_client_id, bucket_name, path, sizes, fmt
                )
            )

            return None

        self.logger.info('[{}] Creating image set for <bucket:{}>, <path:{}> and <sizes:{}>'.format(
            worker.worker_client_id, bucket_name, path, sizes
        ))

        amazon = self.config['services']['amazon']

        conn = S3Connection(amazon['key'], amazon['secret'])

        try:
            bucket = conn.get_bucket(bucket_name)
        except Exception as e:
            self.logger.error(
                '[{}] Failed to access <bucket:{}> with <path:{}>. [{}] {}'.format(
                    worker.worker_client_id, bucket_name, path, e.__class__.__name__, str(e)
                )
            )

            return None

        im_key = S3Key(bucket)
        im_key.key = '{}/{}'.format(path, filename)

        #Create temporary files
        im_fd, im_filename = tempfile.mkstemp()
        resized_fd, resized_filename = tempfile.mkstemp()

        #Close the file so we can save to it using loop construct
        os.close(im_fd)
        os.close(resized_fd)

        #Get image from S3
        try:
            im_key.get_contents_to_filename(im_filename)
        except Exception as e:
            self.logger.error(
                '[{}] Failed to fetch original image for <bucket:{}>, <path:{}> and <sizes:{}>. [{}] {}'.format(
                    worker.worker_client_id, bucket_name, path, sizes, e.__class__.__name__, str(e)
                )
            )

            return None

        im = Image.open(im_filename)

        _format = self.FORMATS[fmt]

        for size in sizes:
            if isinstance(size, (int, long)):
                size = (size, size)

            if size == im.size and im.format == fmt:
                content_filename = im_filename
            else:
                resized = im.copy()
                resized.thumbnail(size, Image.ANTIALIAS)
                resized.save(resized_filename, fmt, **_format['options'])

                content_filename = resized_filename

            #Save to S3 or save for batch upload
            resized_key = S3Key(bucket)
            resized_key.key = '{}/{}.{}'.format(path, size[0], _format['ext'])

            try:
                resized_key.set_contents_from_filename(
                    content_filename, policy='public-read', headers={'Content-Type': _format['mime']}
                )
            except Exception as e:
                self.logger.error(
                    '[{}] Failed to upload thumbnail image for <bucket:{}>, <path:{}> and <size:{}>. [{}] {}'.format(
                        worker.worker_client_id, bucket_name, path, size[0], e.__class__.__name__, str(e)
                    )
                )

        #Delete temporary files
        os.remove(im_filename)
        os.remove(resized_filename)

        end = time.time()

        self.logger.info(
            '[{}] Finished creating image set for <bucket:{}>, <path:{}> and <sizes:{}>. Took {}'.format(
                worker.worker_client_id, bucket_name, path, sizes, dt.timedelta(seconds=(end - start))
            )
        )
