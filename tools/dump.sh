#!/bin/bash

echo "Deleting old dump..."
rm -rf ../dump

echo "Dump usersProfiles with non player profiles..."
mongodump --db castle-staging --collection usersProfiles --query '{profileType: {$ne:"PLAYER"}}' -o ../dump

echo "Dump other collections..."
mongodump --db castle-staging --collection balconomy -o ../dump
mongodump --db castle-staging --collection definition.castles -o ../dump
mongodump --db castle-staging --collection definition.achievements -o ../dump
mongodump --db castle-staging --collection server.config -o ../dump
mongodump --db castle-staging --collection servers.config -o ../dump

echo "-=Dump completed=-"
