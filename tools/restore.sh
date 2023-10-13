#!/bin/bash

echo 'Deleting castle-staging db... '
mongo < deletedb.js

echo 'Restoring fresh castle-staging db...'
export LC_ALL=C; mongorestore -d castle-staging ../dump/castle-staging

echo '-=Finished restoring=-'
