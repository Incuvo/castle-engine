#!/bin/bash

echo 'db.levels.update({"stats.plays_daily" : {$ne : 0 }},{ $set : {"stats.plays_daily" : 0,"stats.ppl2_daily":0}},{multi : true})' | mongo --quiet castle
echo 'db.levels.update({"stats.likes_daily" : {$ne : 0 }},{ $set : {"stats.likes_daily" : 0}},{multi : true})' | mongo --quiet castle