#!/bin/bash
read -p "Caution! Droping and resetting mongo, press CTRL+C if you want to abort!"
echo "dropping balconomy, user and castle collection"
mongo castle-staging --eval "db.balconomy.drop()"
mongo castle-staging --eval "db.definition.castles.drop()"
mongo castle-staging --eval "db.usersProfiles.drop()"


echo "Importing Balconomy"
mongoimport -d castle-staging -c balconomy --file balconomy_fresh.json
echo "Import Castle Definition" 
mongoimport -d castle-staging -c definition.castles --file definition.castles_fresh.json

