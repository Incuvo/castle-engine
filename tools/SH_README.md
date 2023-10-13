#SH SCRIPTS README
Script which are used to do common admin tasks such a dump database, restore database with cleanup (others in future). Scripts are in the root directory. Should be run directly on machine where task is to do.

* dump.sh
* restore.sh
* generate.sh
* deletedb.js

##dump.sh
This script workflow is:

* delete "dump" directoru (which is located in the root)
* dump usersProfiles collection with non player profile type (for now it's only NPC_BOSSES)
* dump other required data as balconomy, starting castle, config etc.

##restore.sh
This script workflow is:

* Run deletedb.js
* Restore all data

##generate.sh
Can be only run after restore.sh

* Generates 30 player accounts by sending v1/init on localhost

##deletedb.js
This is internal script which should be executed only by restore.sh. It's running commands for mongoshell. This script executes mongo shell commands:

* use castle-staging
* drop castle-staging database
