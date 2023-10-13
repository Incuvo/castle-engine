# CHANGELOG
## V6.1.5 release 11.07.2017
* Add 'didUserRateThisApp' to UserProfile
* Add 'maxRateUsRequests' to Balconomy
## V6.1.4 release 05.07.2017
#### Force 6.2
## V6.1.3
* Add 'speed', 'damageType' and 'goodAgainst' params to projectile in balconomy
* Fix resources sync problem in fightHistory
## V6.1.2
* New matchmaking
* Refresh map under clouds when entering game
* Fixed postFinishBuildingImmedietely when time is lower than 0 (NaN error)
* Merged application.auth properties to usersProfile (mongo optimization)
* Changed regex NPC to $ne Player (mongo optimization)
## V6.1.1 release 11.05.2017
#### Force 6.1
* Block init when user is under scout mode
* Application check middleware
## V6.1 release 10.05.2017 (only mongo)
* Updated boss positions
## V6.1 release 28.04.2017
#### Balconomy 0.86
* Clan email
* League optimization
* Tutorial fix (Grayson nid 1)
* PostFinishAmmo rubies range fix
* Random battle exclude map users
## V6 release 20.04.2017
#### Balconomy 0.82
#### Force 6.0 (Android only)
* Ads (Video tent)
* Achievements
* Leagues
* Fixed map locations + new locations
* Starter pack (not released in client)
## V5.1 release 11.04.2017
#### Balconomy 0.75
#### Force V5.x 
## V5 release 30.03.2017
#### Balconomy 0.63 
* Add 'builderCosts' array in Balconomy
## V4
* Add 'projectileOrder' field in Balconomy
## V3.1.4
* IOS hotfix for production client which points for /debug/iap/verify instead of /v3/iap/verify
## V3.1.3
* Added api requests to get stats for fight attacks
* Remove replays after time defined in balconomy
* Limit fight history
## V3.1.2
* Added Logging body when purchase is invalid
* Added api requests to retention stats and purchases
## V3.1.1
* Force old clients to move from v2 to v3
## V3.1 release 09.03.2017
#### Balconomy 0.35
* Fixed fight endings with 0 stars when user is offline
* Fixed proper state when fight ends user is getting state before fight
* Fixed IAP
## V3
* Backward compatibility V2
* New project structure
## V2