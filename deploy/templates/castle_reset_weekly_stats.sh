#!/bin/bash

echo 'db.levels.update({"stats.plays_weekly" : {$ne : 0 }},{ $set : {"stats.plays_weekly" : 0,"stats.ppl2_weekly":0}},{multi : true})' | mongo --quiet castle
echo 'db.levels.update({"stats.likes_weekly" : {$ne : 0 }},{ $set : {"stats.likes_weekly" : 0}},{multi : true})' | mongo --quiet castle