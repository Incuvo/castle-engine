#!/bin/bash

echo "Full castle-staging dump into ~/backup..."

mongodump  --db castle-staging --out ~/backup/dump-`date +%F`
rc=$?; if [[ $rc != 0 ]]; then echo "Something went wrong with database dump, exiting... "; exit $rc; fi

echo "-=Dump completed=-"

## git pull z repo
cd ~/src
git pull
rc=$?; if [[ $rc != 0 ]]; then echo "Something went wrong with git pull, exiting... "; exit $rc; fi

## zmiany do deployu - wszystkie ewentualne skrypty js/sh powinny byc w katalogu current

cd ~/src/deploy/automatic/current
sh changes.sh


## archiwizuj current

cd ~/src/deploy/automatic
tar -zcvf deploy-`date +%F`.tar.gz --remove-files current

## uruchomienie API
