# COMMANDS CHEATSHIT!
## MONGO
Mongo Import (--jsonArray flag when it's human read format)
```
mongoimport --db castle-staging --collection definition.castles --file JSONTOMONGO.json --jsonArray
```
Mongo Export Collection
```
mongoexport --db castle-staging --collection usersProfiles --out usersProfiles.json
```
Mongo Export Query
```
mongoexport -d castle-staging -c usersProfiles --query '{profileType: "NPC_BOSS"}' -o npc_bosses.json
```
Mongo Restore
```
export LC_ALL=C; mongorestore -d castle-staging castle-staging_dump/
```
Mongo Restore Balconomy
```
export LC_ALL=C; mongorestore -d castle-staging -c balconomy dump/castle-staging/balconomy.bson
```
Mongo Dump
```
mongodump -db castle-staging
```
Castle Defeat All Enemies
```
db.usersProfiles.find({display_name: 'kfc'}).forEach(function(doc){doc.map.forEach(function(m){m.defeated=true;});db.usersProfiles.save(doc)})
```
Mongo Aggregate Group
```
db.errors.aggregate([{$group:{_id: '$reason', count: {$sum: 1}}}])
```
## GIT
Git Tag (when switched to desired branch, probably master)
```
git tag -a v3.1.3 -m "Stats requests 2, removed replays, limit history"
```
Git Push Tags
```
git push --tags
```
Git Clean Untracked Shit
```
git clean -fd
```
## VBOX
Vbox Start Machine in background (change CastleDev)
```
VBoxManage startvm CastleDev --type headless
```
Vbox Shutdown Machine
```
VBoxManage controlvm CastleDev poweroff
```
Vbox Symlink Enabled (change SHARED_DIR_NAME to yours)
```
VBoxManage setextradata CastleDev VBoxInternal2/SharedFoldersEnableSymlinksCreate/SHARED_DIR_NAME 1
```
Vbox Check Machine Properties (f.e. IP)
```
VBoxManage guestproperty enumerate CastleDev
```
## UBUNTU
Setup shared directory automount
```
On host system:
* Install Virtual Box Guest Addons
* Setup shared directory in machine settings

On guest system (Ubuntu):
* Add 'vboxsf' to '/etc/modules' (to ensure that sharing vbox module is loaded earlier than normal)
* Create mount point f.e. mkdir ~/castle-server
* Add mount -t vboxsf -o rw,uid=1000,gid=1000 SHARED_DIR_NAME castle-server (vboxsf should be added to /etc/modules before)
```