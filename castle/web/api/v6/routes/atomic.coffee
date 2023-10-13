# Defines atomic requests endpoints.
util = require("util")
crypto = require 'crypto'
mongoose = require 'mongoose'
async = require 'async'
https = require 'https'
http = require 'http'

mm = require '../db/mongodb/models'
mv = require '../model-views'
mw = require '../middleware'
ex = require '../../exceptions'
moment    = require 'moment'
profanity = require '../../../util/profanity'
hashids   = require 'hashids'

xml2js    = require('xml2js')
zlib      = require('zlib')
onesignal = require '../onesignal'

rand = require '../../../util/rand'
generalUtil = require '../../../util/general'
oauth = require './oauth'
timeutils = require '../../../util/time'

GameInn = require './../../../../../GameInn/index.js'

ValidationError = mongoose.Document.ValidationError
ObjectId = mongoose.Types.ObjectId

debugMode = false

# balkonomia: req.app.castle.balconomy
# user:req.castle.user

###
@api {post} /v1/postBoostProduction Triggers boosted production on a room and checks and removes rubies
@apiName postBoostProduction
@apiGroup AtomicResources
@apiParam {hardSpend} rubies spent by client
@apiParam {roomId} what room has been boosted
@apiSuccess {String} status Success status
@apiSuccessExample Success-Response:
    HTTP/1.1 200 OK
    {
    }
@apiError ResetRequired The value does not match balconomy.
@apiErrorExample Error-Response:
    HTTP/1.1 400 Bad Request
    {
        description: 'Reset flag was enabled in UserProfile'
    }
###
exports.postBoostProduction = (req, res, next) ->
    
    user = req.castle.user
    balconomy = req.app.castle.balconomy
    if debugMode
        util.log '[Atomic PostBoostProduction] User: ' + user.username + ', Balconomy: ' + balconomy.getVersion()
        logAtomicMethodEntry('postBoostProduction', user, balconomy.getVersion(), req.body.roomId)
    room = user.getRoom(req.body.roomId)
    
    roomParams = balconomy.getRoomParams(room.roomType, room.roomLevel)

    if roomParams.boostCost == req.body.hardSpend
        # OK - now we need to change user rubies
        if user.removeHard(roomParams.boostCost) == false
            util.log '[ERROR] Couldn removed hard on postBoostProduction boostCost ' + roomParams.boostCost + ' user hard ' + user.currency.hard
            errorData =
                boostCost: roomParams.boostCost
                userHard: user.currency.hard
                user: user.toJSON()
            return next new ex.ResetRequired("","removeHard check - no sufficient Hard at postBoostProduction", errorData)
        
        if user.boostRoomProduction(room) == false
            util.log '[ERROR] Couldn boost room on postBoostProduction'
            return next new ex.ResetRequired("","Could not boost a room")

        if debugMode
            util.log '[Atomic PostBoostProduction] ' + room.name + ' production boosted for user: ' + user
        
        user.save (err, obj) ->
            if err?
                util.log '[ERROR] '+ err + ' saving user: '+ user + ' on postBoostProduction'
                return next new ex.ResetRequired("","postBoostProduction user profile save")
            else
                GameInn.SendEvent 'RESOURCES_BOOST', {userID: user._id, cost: roomParams.boostCost, roomID: req.body.roomId}, (err, data) ->
                    if err?
                        console.log err

                res.json
                    status: 'ok'
            

    else # hardSpend and Boostcost do not match
        util.log '[ERROR] postBoostProduction request value: ' + req.body.hardSpend + ' inconsistent with balconomy value' + roomParams.boostCost
        return next new ex.ResetRequired("","postBoostProduction request value inconsistent with balconomy value")
        # should be HTTP 409 Conflict!

###
@api {post} /v1/postFinishBuildingImmediately Ending building construction immediately
@apiName postFinishBuildingImmediately
@apiGroup AtomicResources
@apiParam {hardSpend} rubies spent by client
@apiParam {roomId} what room has been finished
@apiParam {minutesToFinishConstruction} what minutes were calculated by client
@apiSuccess {String} status Success status
@apiSuccessExample Success-Response:
    HTTP/1.1 200 OK
    {
    }
@apiError ResetRequired The client value does not match server calculations.
@apiErrorExample Error-Response:
    HTTP/1.1 400 Bad Request
    {
        description: 'Reset flag was enabled in UserProfile'
    }
###

exports.postFinishBuildingImmediately = (req, res, next) ->
    
    user = req.castle.user
    balconomy = req.app.castle.balconomy
    if debugMode
        logAtomicMethodEntry('postFinishBuildingImmediately', user, balconomy.getVersion(), req.body.roomId)
    room = user.getRoom(req.body.roomId)

    if room == null
        return next new ex.ResetRequired("MALFORMED_DATA", "Cannot find room for postFinishBuildingImmediately", {roomId: req.body.roomId})

    time = req.body.minutesToFinishConstruction
    gems = req.body.hardSpend

    oddgemsvalue = balconomy.calculateImmediateFinishSettings(time)
    
    if (gems == oddgemsvalue) or (gems == oddgemsvalue + 1) or (gems == oddgemsvalue - 1) or ((gems == 0) and (user.IsTutorialOn()))
        # OK - now we need to change user rubies
        
        # zbierz resources - nie trzeba jeśli jest to robione podczas uruchamiania upgrade!

        #if user.removeHard(roomParams.boostCost) == false <- psoltysik: Jaki boostCost?!
        if user.removeHard(gems) == false
            util.log '[ERROR] Couldn removed hard on postFinishBuildingImmediately gems ' + gems + ' user hard ' + user.currency.hard
            errorData =
                gems: gems
                userHard: user.currency.hard
                user: user.toJSON()
            return next new ex.ResetRequired("","removeHard check - no sufficient Hard at postFinishBuildingImmediately", errorData)
        
        #if user.resetCollectTime(room) and user.finishRoomProduction(room) == false <- psoltysik: Zaraz po tym requescie przychodzi FinishBuilding, dlatego należy cofnąć czas startu budowy o nawet rok
        #    return next new ex.ResetRequired("","Could not finish a room")

        room.buildingStartTimestamp = "01/01/1990 00:00:00"
        room.lastCollectTime = timeutils.timestampToClientTimeformat(Date.now())
        
        user.save (err, obj) ->
            if err?
                util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postFinishBuildingImmediately'
                return true
            else
                GameInn.SendEvent 'FINISH_NOW', {userID: user._id, type: "ROOM", roomID: req.body.roomId, ruby: user.currency.hard}, (err, data) ->
                    if err?
                        console.log err

                if debugMode
                    util.log '[Atomic PostFinishBuildingImmediately] Room ' + room.name + ' production finished for user: ' + user.username
                res.json
                    status: 'ok'

    else # gems <> oddgemsvalue
        util.log '[ERROR] postFinishBuildingImmediately calculated hard: ' + oddgemsvalue + ' not consistent with client send: ' + gems
        return next new ex.ResetRequired("","postFinishBuildingImmediately request value:" + gems + " inconsistent with calculated value:" + oddgemsvalue)
        # should be HTTP 409 Conflict!

###
@api {post} /v1/postFinishAmmoProduction Ending building construction immediately
@apiName postFinishAmmoProduction
@apiGroup AtomicResources
"{
  ""hardSpend"": 0,
  ""secondsToFinishAmmoProduction"": 0
}"
@apiParam {hardSpend} rubies spent by client
@apiParam {secondsToFinishAmmoProduction} what seconds were to finish ammo
@apiSuccess {String} status Success status
@apiSuccessExample Success-Response:
    HTTP/1.1 200 OK
    {
    }
@apiError ResetRequired The client value does not match server calculations.
@apiErrorExample Error-Response:
    HTTP/1.1 400 Bad Request
    {
        description: 'Reset flag was enabled in UserProfile'
    }
###

exports.postFinishAmmoProduction = (req, res, next) ->
    
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if debugMode
        logAtomicMethodEntry('postFinishAmmoProduction', user, balconomy.getVersion())
    
    # Add control
    secs = req.body.secondsToFinishAmmoProduction
    time = secs / 60 # time = minutesToFinishConstruction

    gems = req.body.hardSpend
    roundgemsvalue = balconomy.calculateImmediateFinishSettings(time, balconomy.getProjectileProductionHardCostMultiplier())

    if (gems >= roundgemsvalue - 1) or ((gems == 0) and (user.IsTutorialOn()))
        # OK - now we need to change user rubies
        
        # zbierz resources - nie trzeba jeśli jest to robione podczas uruchamiania upgrade!

        if user.removeHard(gems) == false
            util.log '[ERROR] Couldn removed hard on postFinishAmmoProduction gems ' + gems + ' user hard ' + user.currency.hard
            errorData =
                gems: gems
                userHard: user.currency.hard
                user: user.toJSON()
            return next new ex.ResetRequired("","removeHard check - no sufficient Hard at postFinishAmmoProduction", errorData)
        
        if user.finishAmmoImmediately() == false
            util.log '[ERROR] No ammo produce on postFinishAmmoProduction, user: '+ user.username + '(' + user.display_name + ')'
            return next new ex.ResetRequired("","Could not finish ammo production")
        
        user.save (err, obj) ->
            if err?
                util.log '[ERROR] ' + err + ' saving user: ' + user.username + ' on postFinishAmmoProduction'
                return next new ex.ResetRequired("","postFinishAmmoProduction user profile save")
            else
                GameInn.SendEvent 'FINISH_NOW', {userID: user._id, type: "AMMO", ruby: user.currency.hard}, (err, data) ->
                    if err?
                        console.log err

                res.json
                    status: 'ok'

    else # gems <> oddgemsvalue
        util.log '[ERROR] postFinishAmmoProduction calculated hard: '+roundgemsvalue+' inconsistent with client send: '+gems
        return next new ex.ResetRequired("","postFinishAmmoProduction request value:"+gems+" inconsistent with calculated value:"+roundgemsvalue)
        # should be HTTP 409 Conflict!


###
@api {post} /v1/postFinishAmmoProduction Ending ammo research immediately
@apiName postFinishAmmoProduction
@apiGroup AtomicResources
"{
  ""hardSpend"": 0,
  ""minutesToFinishResearch"": 0
}"
@apiParam {hardSpend} rubies spent by client
@apiParam {minutesToFinishResearch} what minutes were to finish ammo research
@apiSuccess {String} status Success status
@apiSuccessExample Success-Response:
    HTTP/1.1 200 OK
    {
    }
@apiError ResetRequired The client value does not match server calculations.
@apiErrorExample Error-Response:
    HTTP/1.1 400 Bad Request
    {
        description: 'Reset flag was enabled in UserProfile'
    }
###

exports.postFinishResearchProjectileImmediately = (req, res, next) ->
    
    user = req.castle.user
    balconomy = req.app.castle.balconomy
    if debugMode
        logAtomicMethodEntry('postFinishResearchProjectileImmediately', user, balconomy.getVersion())
    
    # HERE COMPARE time calculated to time given in request (with error margin)
    
    time = req.body.minutesToFinishResearch
    #time = secs / 60 # time = minutesToFinishConstruction
    gems = req.body.hardSpend
    
    roundgemsvalue = balconomy.calculateImmediateFinishSettings time
    #oddgemsvalue = 2 * Math.floor(gemsvalue / 2) + 1
    #roundgemsvalue = Math.round(gemsvalue) # ROUND TO INT IN CLIENT MAY BE PROBLEMATIC!


    if (gems == roundgemsvalue) or (gems == roundgemsvalue + 1) or (gems == roundgemsvalue - 1)
        # OK - now we need to change user rubies
        
        # zbierz resources - nie trzeba jeśli jest to robione podczas uruchamiania upgrade!

        if user.removeHard(gems) == false
            util.log '[ERROR] Couldn removed hard on postBoostProduction gems ' + gems + ' user hard ' + user.currency.hard
            return next new ex.ResetRequired("","finishResearchProjectileImmediately check - no sufficient Hard")

        user.castle.ammoResearch.researchStartTimestamp = "01/01/1990 00:00:00"
        #if user.finishProjectileResearchImmediately() == false
        #    return next new ex.ResetRequired("","Could not finish ammo research")
        
        user.save (err, obj) ->
            if err?
                util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postFinishResearchProjectileImmediately'
                return next new ex.ResetRequired("","postFinishResearchProjectileImmediately user profile save")
            else
                GameInn.SendEvent 'FINISH_NOW', {userID: user._id, type: "RESEARCH", research: user.castle.ammoResearch.projectileId, ruby: gems}, (err, data) ->
                    if err?
                        console.log err

                res.json
                    status: 'ok'

    else # gems <> oddgemsvalue
        util.log '[ERROR] postFinishResearchProjectileImmediately calculated hard: ' + roundgemsvalue + ' inconsistent with client send: ' + gems
        return next new ex.ResetRequired("","postFinishResearchProjectileImmediately request value:" + gems + " inconsistent with calculated value:" + roundgemsvalue)
        # should be HTTP 409 Conflict!

exports.postBuyRoom = (req, res, next) ->

    user = req.castle.user
    balconomy = req.app.castle.balconomy
    
    if debugMode
        logAtomicMethodEntry('postBuyRoom', user, balconomy.getVersion(), req.body.roomType, req.body.clientBuilidingStartTimestamp)

    clientBuildingStartTimestamp = timeutils.clientTimeformatToTimestamp(req.body.clientBuilidingStartTimestamp)
    serverCompareTimestamp = Date.now() - 30000
    
    if debugMode
        logExpressiveTimeInfo(serverCompareTimestamp + 30000, req.body.clientBuilidingStartTimestamp)
    
    if ((serverCompareTimestamp) > clientBuildingStartTimestamp)
        util.log "[WARN] postBuyRoom request - client timestamp: " + clientBuildingStartTimestamp + ", server compare: " + serverCompareTimestamp
        
    nowDate = Date.now() - 300000 # temporary fix, 5 minutes
    if(nowDate > clientBuildingStartTimestamp)
        util.log "[ERROR] postBuyRoom request - client timestamp: " + clientBuildingStartTimestamp + ", server compare: " + nowDate
        return next new ex.ResetRequired("","postBuyRoom request - client timestamp: " + clientBuildingStartTimestamp + ", server compare: " + nowDate)

    # check limit room
    throneHallLevel = user.getThroneLevel()
    roomCount = user.getRoomCount(req.body.roomType)
    roomLimit = balconomy.getRoomLimits(req.body.roomType, throneHallLevel)

    if(roomLimit.roomLimit < roomCount + 1)
        util.log '[ERROR] postBuyRoom request roomLimit reached, roomLimit: ' + roomLimit.roomLimit + ' roomCount: ' + roomCount
        return next new ex.ResetRequired("","postBuyRoom request roomLimit reached")

    # check price
    roomParams = balconomy.getRoomParams(req.body.roomType, 1)
    roomDefinition = balconomy.getRoomDefinition(req.body.roomType)
    roomCostValue = roomParams.costValue

    if(req.body.roomType == "BUILDER")
        roomCostValue = balconomy.getBuilderCost(roomCount)
    
    if(roomCostValue != req.body.resourceQuantity || roomDefinition.buyCostCategoryId != balconomy.resolveCostCategoryId(req.body.resourceType))
        util.log '[ERROR] postBuyRoom request price ' + req.body.resourceQuantity + ' inconsistent with balconomy value ' + roomCostValue + ' buyCostCategoryId ' + roomDefinition.buyCostCategoryId + ' resolvedCategoryId ' + balconomy.resolveCostCategoryId(req.body.resourceType)
        return next new ex.ResetRequired("","postBuyRoom request price inconsistent with balconomy value")

    if(user.getFreeBuildersCount() <= 0 && req.body.roomType != "BUILDER")
        util.log '[ERROR] postBuyRoom no free builder ' + user.getFreeBuildersCount() + ' roomType ' + req.body.roomType
        return next new ex.ResetRequired("","postBuyRoom request - no free builder")

    if(req.body.resourceType == 'RUBY')
        if(!user.removeHard(req.body.resourceQuantity))
            util.log '[ERROR] Couldn removed hard on postBuyRoom gems ' + req.body.resourceQuantity + ' user hard ' + user.currency.hard
            return next new ex.ResetRequired("","postBuyRoom request - not enough Ruby")

    else
        if(!user.removeResourceFromStorage(req.body.resourceQuantity, req.body.resourceType))
            util.log '[ERROR] postBuyRoom not enough resources ' + req.body.resourceQuantity + ' ' + req.body.resourceType
            return next new ex.ResetRequired("","postBuyRoom request - not enough resources")

    if roomCount == 0 and req.body.roomType == 'ARCHER'
        user.setTutorialState 14

    if roomCount == 1 and req.body.roomType == 'FORTIFICATIONS_ROOF'
        user.setTutorialState 21

    #: this request needs to have coordinates for room given in a request body! This should ensure right castle mapping on the server
    user.addBuildRoom(balconomy.resolveRoomId(req.body.roomType), req.body.roomType, req.body.xPosition, req.body.yPosition, clientBuildingStartTimestamp, clientBuildingStartTimestamp + roomParams.constructionTime * 1000)

    user.save (err, userProfile) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on PostBuyRoom'
            return next new ex.ResetRequired("","PostBuyRoom user profile save")

        GameInn.SendEvent 'BUY_ROOM', {userID: user._id, roomType: req.body.roomType, cost: req.body.resourceQuantity, resourceType: req.body.resourceType, constructionTime: roomParams.constructionTime * 1000}, (err, data) ->
            if err?
                console.log err

        res.json
            status: 'ok'

exports.postCancelBuildingRoom = (req, res, next) ->

    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if debugMode
        logAtomicMethodEntry('postCancelBuildingRoom', user, balconomy.getVersion(), req.body.roomId)

    room = user.getRoom(req.body.roomId)

    if(room == null)
        util.log '[ERROR] postCancelBuildingRoom roomId not found ' + req.body.roomId
        return next new ex.ResetRequired("","postCancelBuildingRoom request - roomId not found")

    if(room.buildingStartTimestamp == '01/01/0001 00:00:00')
        util.log '[ERROR] postCancelBuildingRoom room not under construction buildingStartTimestamp ' + room.buildingStartTimestamp + ' should be different than 01/01/0001 00:00:00'
        return next new ex.ResetRequired("","postCancelBuildingRoom request - room isnt under construction")

    roomParams = balconomy.getRoomParams(room.roomType, room.roomLevel + 1)
    roomDefinition = balconomy.getRoomDefinition(room.roomType)
    if (room.roomLevel > 0)
        resourceType = balconomy.resolveCostCategoryType(roomDefinition.upgradeCostCategoryId)
    else
        resourceType = balconomy.resolveCostCategoryType(roomDefinition.buyCostCategoryId)
    
    resourceQuantity = roomParams.costValue

    if(room.roomType == 'BUILDER' && room.roomLevel == 0)
        resourceQuantity = balconomy.getBuilderCost(user.getRoomCount(req.body.roomType) - 1)

    if(resourceType == 'RUBY')
        if(!user.addHard(resourceQuantity,false))
            util.log '[ERROR] postCancelBuildingRoom request - addHard error'
            return next new ex.ResetRequired("","postCancelBuildingRoom request - something goes wrong - addHard")

    else
        if(!user.addResourceToStorage(resourceQuantity, resourceType, balconomy))
            util.log '[ERROR] postCancelBuildingRoom request - addResourceToStorage resourceType: '+resourceType+' not found'
            return next new ex.ResetRequired("","postCancelBuildingRoom request - resourceType not found")

    timeLeft = timeutils.clientTimeformatToTimestamp(room.buildingStartTimestamp) - Date.now()

    user.cancelBuildingRoom(req.body.roomId)

    user.save (err, userProfile) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postCancelBuildingRoom'
            return next new ex.ResetRequired("","postCancelBuildingRoom user profile save")

        GameInn.SendEvent 'CANCEL_BUILDING', {userID: user._id, roomID: req.body.roomId, roomLevel: room.roomLevel, resourceType: resourceType, resourceAmount: resourceQuantity, timeLeft: timeLeft}, (err, data) ->
            if err?
                console.log err

        res.json
            status: 'ok'

exports.postDestroyFortification = (req, res, next) ->

    FORTIFICATION_RETURNED_PRICE_PERCENTAGE = 0.1
    user = req.castle.user
    balconomy = req.app.castle.balconomy
    
    if debugMode
        logAtomicMethodEntry('postDestroyFortification', user, balconomy.getVersion(), req.body.roomId)

    room = user.getRoom(req.body.roomId)

    if(room == null)
        util.log '[ERROR] postDestroyFortification roomId not found ' + req.body.roomId
        return next new ex.ResetRequired("","postDestroyFortification request - roomId not found")

    if(!balconomy.isFortificationRoom(room.roomType))
        util.log '[ERROR] postDestroyFortification room ' + room.roomType + ' not fortification'
        return next new ex.ResetRequired("","postDestroyFortification request - room isnt fortification")

    if(room.buildingStartTimestamp != '01/01/0001 00:00:00')
        util.log '[ERROR] postDestroyFortification room under construction buildingStartTimestamp ' + room.buildingStartTimestamp + ' should be equal ' + '01/01/0001 00:00:00'
        return next new ex.ResetRequired("","postDestroyFortification request - room is under construction")

    roomParams = balconomy.getRoomParams(room.roomType, room.roomLevel)
    roomDefinition = balconomy.getRoomDefinition(room.roomType)

    if (room.roomLevel > 0)
        resourceType = balconomy.resolveCostCategoryType(roomDefinition.upgradeCostCategoryId)
    else
        resourceType = balconomy.resolveCostCategoryType(roomDefinition.buyCostCategoryId)

    resourceQuantity = roomParams.costValue

    if(resourceType == 'RUBY')
        if(!user.addHard(Math.round(resourceQuantity * FORTIFICATION_RETURNED_PRICE_PERCENTAGE),false))
            util.log '[ERROR] postDestroyFortification couldnt add rubies resourceQuantity ' + resourceQuantity + ' FORTIFICATION_RETURNED_PRICE_PERCENTAGE ' + FORTIFICATION_RETURNED_PRICE_PERCENTAGE
            return next new ex.ResetRequired("","postDestroyFortification request - something goes wrong - addHard")
    else
        if(!user.addResourceToStorage(Math.round(resourceQuantity * FORTIFICATION_RETURNED_PRICE_PERCENTAGE), resourceType, balconomy))
            util.log '[ERROR] postDestroyFortification couldnt add resourceType ' + resourceType + ' resourceQuantity ' + resourceQuantity + ' FORTIFICATION_RETURNED_PRICE_PERCENTAGE ' + FORTIFICATION_RETURNED_PRICE_PERCENTAGE
            return next new ex.ResetRequired("","postDestroyFortification request - resourceType not found")

    user.removeRoom(req.body.roomId)

    user.save (err, userProfile) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postDestroyFortification'
            return next new ex.ResetRequired("","postDestroyFortification user profile save")

        res.json
            status: 'ok'

exports.postUpgradeRoom = (req, res, next) ->

    user = req.castle.user
    balconomy = req.app.castle.balconomy
    
    if debugMode
        logAtomicMethodEntry('postUpgradeRoom', user, balconomy.getVersion(), req.body.roomId)

    room = user.getRoom(req.body.roomId)
    
    if(room == null)
        util.log '[ERROR] postUpgradeRoom roomId not found ' + req.body.roomId
        return next new ex.ResetRequired("","postUpgradeRoom request - roomId not found")

    if(room.buildingStartTimestamp != '01/01/0001 00:00:00')
        util.log '[ERROR] postUpgradeRoom room under construction buildingStartTimestamp ' + room.buildingStartTimestamp + ' should be equal 01/01/0001 00:00:00'
        return next new ex.ResetRequired("","postUpgradeRoom request - room is under construction")

    clientBuildingStartTimestamp = timeutils.clientTimeformatToTimestamp(req.body.clientBuilidingStartTimestamp)
    serverCompareTimestamp = Date.now() - 30000
    
    if debugMode
        logExpressiveTimeInfo((serverCompareTimestamp + 30000), req.body.clientBuilidingStartTimestamp)
    
    if(serverCompareTimestamp > clientBuildingStartTimestamp)
        if debugMode
            util.log "[WARN] Atomic UpgradeRoom request - client timestamp: " + clientBuildingStartTimestamp + ", server compare is bigger: " + serverCompareTimestamp + 'which is: ' + ( (serverCompareTimestamp - clientBuildingStartTimestamp) / 1000.0 ) + ' seconds.'
        
    if(serverCompareTimestamp > (clientBuildingStartTimestamp + 300000)) # temporary fix
        util.log "[ERROR] UpgradeRoom request - client timestamp: " + clientBuildingStartTimestamp + ", server compare is bigger than 5 mins: " + serverCompareTimestamp + 'which is: ' + ( (serverCompareTimestamp - clientBuildingStartTimestamp) / 1000.0 ) + ' seconds.'
        errorData =
            serverCompareTimestamp: serverCompareTimestamp
            clientBuildingStartTimestamp: clientBuildingStartTimestamp
        return next new ex.ResetRequired("","postUpgradeRoom request - timestamp is incorrect", errorData)

    throneHallLevel = user.getThroneLevel()
    roomLimits = balconomy.getRoomLimits(room.roomType, throneHallLevel)
    
    if(room.roomLevel + 1 > roomLimits.maxRoomLevel)
        util.log '[ERROR] postUpgradeRoom maxRoomLevel reached, roomId: ' + req.body.roomId + ', user: '+user.username+'('+user.display_name+')'
        return next new ex.ResetRequired("","postUpgradeRoom request - maxRoomLevel reached")

    roomParams = balconomy.getRoomParams(room.roomType, room.roomLevel + 1)
    roomDefinition = balconomy.getRoomDefinition(room.roomType)

    resourceType = balconomy.resolveCostCategoryType(roomDefinition.upgradeCostCategoryId)
    roomCostValue = roomParams.costValue

    if(resourceType == 'RUBY')
        if(!user.removeHard(req.body.resourceQuantity))
            util.log '[ERROR] Couldn removed hard on postUpgradeRoom gems ' + req.body.resourceQuantity + ' user hard ' + user.currency.hard
            return next new ex.ResetRequired("","postUpgradeRoom request - not enough Ruby")

    else
        if(!user.removeResourceFromStorage(roomCostValue, resourceType))
            util.log '[ERROR] Couldn removed '+resourceType+' on postUpgradeRoom, cost: '+roomCostValue
            return next new ex.ResetRequired("","postUpgradeRoom request - not enough resources")

    room.buildingStartTimestamp = req.body.clientBuilidingStartTimestamp
    # WTF?????
    room.lastCollectTime = timeutils.timestampToClientTimeformat(clientBuildingStartTimestamp + roomParams.constructionTime * 1000)

    if room.roomType == 'THRONE' and room.roomLevel == 1
        user.setTutorialState 66

    user.save (err, userProfile) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postUpgradeRoom'
            return next new ex.ResetRequired("","postUpgradeRoom user profile save")

        GameInn.SendEvent 'BUY_ROOM', {userID: user._id, roomType: room.roomType, roomLevel: room.roomLevel, cost: roomCostValue, resourceType: resourceType, constructionTime: roomParams.constructionTime * 1000}, (err, data) ->
            if err?
                console.log err

        res.json
            status: 'ok'

exports.exchangeResources = (req, res, next) ->
    hardSpend = req.body.hardSpend
    resourceType = req.body.resourceType
    resourceQuantity = req.body.resourceQuantity

    user = req.castle.user
    balconomy = req.app.castle.balconomy
    
    if debugMode
        logAtomicMethodEntry('exchangeResources', user, balconomy.getVersion(), req.body.resourceType, req.body.resourceQuantity)

    estimatedHard = balconomy.getExchangeCost resourceQuantity
    if debugMode
        util.log 'Client spends: ' + hardSpend + ' rubies. We calculate it should be: ' + estimatedHard
    if not ( (estimatedHard > hardSpend - 2) and (estimatedHard < hardSpend + 2) ) #Kowciu: Math.abs
        if debugMode
            util.log '[WARN] exchange resource doesn\'t match: hardSpend ' + hardSpend + ' estimatedHard ' + estimatedHard + ' for resourceQuantity ' + resourceQuantity
        return next new ex.ResetRequired("","Resource exchange rate doesn\'t match")

    if not user.addResourceToStorage(resourceQuantity, resourceType, balconomy)
        util.log '[ERROR] exchangeResources request - addResourceToStorage resourceType: '+resourceType+' not found'
        return next new ex.ResetRequired("","exchangeResources request - resourceType not found")

    if(not user.removeHard(hardSpend))
        util.log '[ERROR] Couldn removed hard on exchangeResources gems ' + hardSpend + ' user hard ' + user.currency.hard
        return next new ex.ResetRequired("","exchangeResources request - not enough Ruby")

    user.save (err, userProfile) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on exchangeResources'
            return next new ex.ResetRequired("","exchangeResources user profile save")

        res.json
            status: 'ok'

exports.postResearchProjectile = (req, res, next) ->

    user = req.castle.user
    balconomy = req.app.castle.balconomy
    if debugMode
        logAtomicMethodEntry('postResearchProjectile', user, balconomy.getVersion(), req.body.projectileId)

    if(user.isAnyProjectileResearching())
        return next new ex.ResetRequired("","postResearchProjectile request - research in progress")

    projectileLevel = user.getAmmoLevel(req.body.projectileId)
    projectileParams = balconomy.getProjectileParams(req.body.projectileId, projectileLevel + 1)
    projectileDefinition = balconomy.getProjectileDefinition(req.body.projectileId)

    resourceType = balconomy.resolveCostCategoryType(projectileDefinition.costCategoryId)

    if(resourceType == 'RUBY')
        if(!user.removeHard(projectileParams.researchCost))
            util.log '[ERROR] Couldn removed hard on postResearchProjectile gems ' + projectileParams.researchCost + ' user hard ' + user.currency.hard
            return next new ex.ResetRequired("","postResearchProjectile request - not enough Ruby")

    else
        if(!user.removeResourceFromStorage(projectileParams.researchCost, resourceType))
            util.log '[ERROR] postResearchProjectile not enough resources ' + req.body.resourceQuantity + ' ' + req.body.resourceType
            return next new ex.ResetRequired("","postResearchProjectile request - not enough resources")

    user.startResearchProjectile(req.body.projectileId, projectileLevel + 1)

    user.save (err, userProfile) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postResearchProjectile'
            return next new ex.ResetRequired("","postResearchProjectile user profile save")

        GameInn.SendEvent 'RESEARCH_AMMO', {userID: user._id, projectileID: req.body.projectileId, projectileLevel: projectileLevel, resourceType: resourceType, resourceAmount: projectileParams.researchCost, researchTime: projectileParams.researchTime}, (err, data) ->
            if err?
                console.log err  

        res.json
            status: 'ok'

###
@api {post} /v1/postProduceAmmo Ammo is sent to production
@apiName postProduceAmmo
@apiGroup AtomicResources
"{
  ""projectileId"": 0,
}"
@apiParam {projectileId} rubies spent by client
@apiSuccess {String} status Success status
@apiSuccessExample Success-Response:
    HTTP/1.1 200 OK
    {
    }
@apiError ResetRequired Not being able to produce ammo of such level.
@apiErrorExample Error-Response:
    HTTP/1.1 400 Bad Request
    {
        description: 'Reset flag was enabled in UserProfile'
    }
###

exports.postProduceAmmo = (req, res, next) ->
    
    user = req.castle.user
    balconomy = req.app.castle.balconomy
    if debugMode
        logAtomicMethodEntry('postProduceAmmo', user, balconomy.getVersion(), req.body.projectileId, req.body.projectileAmount)

    serverCompareTimestamp = Date.now() - 300000
    productionStartTimestamp = timeutils.clientTimeformatToTimestamp(req.body.productionStartTimestamp)
    
    if debugMode
        logExpressiveTimeInfo((serverCompareTimestamp + 300000), req.body.productionStartTimestamp)
    
    if(serverCompareTimestamp > productionStartTimestamp)
        differenceTS = serverCompareTimestamp - productionStartTimestamp
        if debugMode
            util.log '-------------- It differs by: ' + (differenceTS / 1000.0) + 'seconds. Resetting client...'
        return next new ex.ResetRequired("","postProduceAmmo request - wrong productionStartTimestamp")
    
    projectileDefinition = balconomy.getProjectileDefinition(req.body.projectileId)
    projectileLevelParams = balconomy.getProjectileParams(req.body.projectileId, user.getAmmoLevel(req.body.projectileId))

    #projectileDefinition.armoryLevelRequirement compare to user
    if (user.getArmoryMaxLevel() >= projectileDefinition.armoryLevelRequirement)
        
    # check resources
        if req.body.projectileAmount?
            projectileAmount = req.body.projectileAmount
        else
            if debugMode
                util.log ' -------- no amount of projectiles specified ----------'
            projectileAmount = 1

        if(projectileDefinition.costCategoryId == 'RUBY')
            if(!user.removeHard(projectileLevelParams.costValue * projectileAmount))
                util.log '[ERROR] Couldn removed hard on postProduceAmmo gems ' + (projectileLevelParams.costValue * projectileAmount) + ' user hard ' + user.currency.hard
                return next new ex.ResetRequired("","postProduceAmmo request - not enough Ruby")

        else
            if debugMode
                util.log '--- Taking resources: ' + (projectileLevelParams.costValue * projectileAmount) + ', type: ' + balconomy.resolveCostCategoryType(projectileDefinition.costCategoryId)
            if(!user.removeResourceFromStorage(projectileLevelParams.costValue * projectileAmount, balconomy.resolveCostCategoryType(projectileDefinition.costCategoryId)))
                util.log '[ERROR] Couldn removed ' + balconomy.resolveCostCategoryType(projectileDefinition.costCategoryId) + ' on postProduceAmmo'
                return next new ex.ResetRequired("","postProduceAmmo request - not enough resources")

    # dodac pociski do kolejki
        if user.addAmmoToProduction(req.body.projectileId, projectileAmount, productionStartTimestamp) == false
            return next new ex.ResetRequired("","Could not add projectile to production")
        
        user.save (err, obj) ->
            if err?
                util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on addAmmoToProduction'
                return next new ex.ResetRequired("","addAmmoToProduction user profile save")
            else
                GameInn.SendEvent 'BUY_AMMO', {userID: user._id, projectileID: req.body.projectileId, projectileAmount: projectileAmount}, (err, data) ->
                    if err?
                        console.log err

                if debugMode
                    util.log '[addAmmoToProduction] Projectile production started for user: ' + user.username
                res.json
                    status: 'ok'

    else # armory Level < requested ammo production
        return next new ex.ResetRequired("","postProduceAmmo request - not enough Armory Level")
        # should be HTTP 409 Conflict!

exports.collectResourceFromCollectors = (req, res, next) ->
    roomId = req.body.roomId
    resourceType = req.body.resourceType
    resourceQuantity = req.body.resourceQuantity
    collectTimestamp = req.body.collectTimestamp
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if debugMode
        logAtomicMethodEntry('collectResourceFromCollectors', user, balconomy.getVersion(), req.body.roomId, req.body.resourceQuantity)

    error = true

    for resourceRoom in user.castle.roomsList
        if resourceRoom.name == roomId
            #total produced
            producedQuantity = mv.UserProfile.calculateResourceInRoom resourceRoom, balconomy, collectTimestamp
            currentQuantity = user.getResourceFromStorages resourceType
            resourceLimit = if resourceType == 'GOLD' then user.getGoldLimit(balconomy) else user.getManaLimit(balconomy)
            #total to collect
            predictedQuantity = producedQuantity
            #how much will be in collector after collect if we have space there should be 0
            resourceProdQuantity = 0
            if debugMode
                util.log '--- currentQuantity: ' + currentQuantity + ', producedQuantity: ' + producedQuantity + ', currentQuantity + producedQuantity: ' + (currentQuantity + producedQuantity)
            if currentQuantity + producedQuantity > resourceLimit
                #we don't have expected space to collect
                resourceProdQuantity = currentQuantity + producedQuantity - resourceLimit
                predictedQuantity = producedQuantity - resourceProdQuantity
            
            if debugMode
                util.log '--- resourceLimit ' + resourceLimit + ', resourceProdQuantity: ' + resourceProdQuantity + ', predictedQuantity: ' + predictedQuantity

            if Math.abs(predictedQuantity - resourceQuantity) > 10
                util.log '[WARN] Collect doesnt match, predictedQuantity(server): ' + predictedQuantity + ' resourceQuantity(client): '+resourceQuantity
                break

            resourceRoom.resourceProdQuantity = resourceProdQuantity
            resourceRoom.lastCollectTime = timeutils.timestampToClientTimeformat collectTimestamp

            error = false

            break

    if error
        util.log '[ERROR] collectResourceFromCollectors error not found or value mismatch: '+roomId
        errorData =
            user: user.toJSON()
            roomId: req.body.roomId
            client:
                resourceQuantity: req.body.resourceQuantity
                collectTimestamp: collectTimestamp
                collectTimestampNice: timeutils.timestampToClientTimeformat collectTimestamp
            server:
                currentQuantity: currentQuantity
                producedQuantity: producedQuantity
                resourceLimit: resourceLimit
                predictedQuantity: predictedQuantity
                resourceProdQuantity: resourceProdQuantity

        return next new ex.ResetRequired("","Produced quantity does not match", errorData)

    if not user.addResourceToStorage resourceQuantity, resourceType, balconomy
        util.log '[ERROR] collectResourceFromCollectors request - addResourceToStorage resourceType: '+resourceType+' not found'
        return next new ex.ResetRequired('', 'Cannot add resource to storage')

    user.save (err, obj) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on collectResourceFromCollectors'
            return next new ex.ResetRequired("","collectResourceFromCollectors user profile save")

        GameInn.SendEvent 'COLLECT_RESOURCES', {userID: user._id, resources: [{type: resourceType, amount: resourceQuantity, location: roomId}]}, (err, data) ->
            if err?
                console.log err

        # WTF???????????
        if debugMode
            util.log '--- lastCollect: ' + obj.getRoom(roomId).lastCollectTime
        res.json
            status: 'ok'


exports.postFinishBuilding = (req, res, next) ->
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if debugMode
        logAtomicMethodEntry('postFinishBuilding', user, balconomy.getVersion(), req.body.roomId)
    
    room = user.getRoom(req.body.roomId)
    
    if(room == null)
        util.log '[ERROR] postFinishBuilding roomId not found ' + req.body.roomId
        return next new ex.ResetRequired("","postFinishBuilding request - roomId not found")

    if(room.buildingStartTimestamp == '01/01/0001 00:00:00')
        util.log '[ERROR] postFinishBuilding room isnt under construction buildingStartTimestamp ' + room.buildingStartTimestamp + ' should be equal ' + '01/01/0001 00:00:00'
        return next new ex.ResetRequired("","postFinishBuilding request - room isnt under construction")

    startTimestamp = timeutils.clientTimeformatToTimestamp(room.buildingStartTimestamp)

    roomParams = balconomy.getRoomParams(room.roomType, room.roomLevel + 1)

    dateNow = Date.now() + 30000

    if(dateNow < startTimestamp + roomParams.constructionTime)
        util.log '[ERROR] postFinishBuilding room hasnt finished yet ' + req.body.roomId + ' should be end ' + timeutils.timestampToClientTimeformat(startTimestamp + roomParams.constructionTime)
        errorData =
            user: user.toJSON()
            room:
                dateNow: dateNow
                startTimestamp: startTimestamp
                constructionTime: roomParams.constructionTime
        return next new ex.ResetRequired("","postFinishBuilding request - room hasnt finished yet", errorData)

    user.finishRoomProduction(room)
    achivementId = balconomy.resolveUpgradeAchivementId(room.roomType)
    if achivementId != 'none'
        user.setAchievementProgress(achivementId, room.roomLevel)
    #user.resetCollectTime(room)

    user.save (err, userProfile) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postFinishBuilding'
            return next new ex.ResetRequired("","postFinishBuilding user profile save")

        res.json
            status: 'ok'


###
@api {post} /v1/postFlipFortification
@apiName postFlipFortification
@apiGroup AtomicResources
"{
  ""roomId"": 0,
}"
@apiParam {roomId} room (fortification) flipped by client
@apiSuccess {String} status Success status
@apiSuccessExample Success-Response:
    HTTP/1.1 200 OK
    {
    }

@apiError ResetRequired Not being able to flip fortification

@apiErrorExample Error-Response:
    HTTP/1.1 400 Bad Request
    {
        description: 'Reset flag was enabled in UserProfile'
    }
###

exports.postFlipFortification = (req, res, next) ->
    
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if debugMode
        logAtomicMethodEntry('postFlipFortification', user, balconomy.getVersion(), req.body.roomId)
    
    room = user.getRoom(req.body.roomId)

    if(room == null)
        util.log '[ERROR] postFlipFortification roomId not found ' + req.body.roomId
        return next new ex.ResetRequired("","postFlipFortification request - roomId not found")

    #projectileDefinition.armoryLevelRequirement compare to user
    if (!user.flipRoom(room))
        util.log '[ERROR] Room '+req.body.roomId+' is not flippable'
        return next new ex.ResetRequired("","postFlipFortification request - not flippable")
    # check resources

    user.save (err, obj) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postFlipFortification'
            return next new ex.ResetRequired("","postFlipFortification user profile save")
        else
            if debugMode
                util.log '[postFlipFortification] Fortification flipped by user: ' + user.username
            res.json
                status: 'ok'

exports.postSetRoomPosition = (req, res, next) ->

    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if debugMode
        logAtomicMethodEntry('postSetRoomPosition', user, balconomy.getVersion(), req.body.roomId, req.body.xPosition + ':' + req.body.yPosition)

    room = user.getRoom(req.body.roomId)
    
    if(room == null)
        util.log '[ERROR] postSetRoomPosition roomId not found ' + req.body.roomId
        return next new ex.ResetRequired("","postSetRoomPosition request - roomId not found")

    user.setRoomPosition(room.layoutID, req.body.xPosition, req.body.yPosition)

    user.save (err, userProfile) ->
        if err?
            util.log '[UserProfile] Error: '+ err + ' saving user: '+ user.username + ' on postSetRoomPosition'
            return next new ex.ResetRequired("","postSetRoomPosition user profile save")

        res.json
            status: 'ok'

exports.postFinishResearchProjectile = (req, res, next) ->
    
    user = req.castle.user
    balconomy = req.app.castle.balconomy
    if debugMode
        logAtomicMethodEntry('postFinishResearchProjectile', user, balconomy.getVersion(), 'minutes to finish', req.body.minutesToFinishResearch)
    
    time = req.body.minutesToFinishResearch

    if(!user.isAnyProjectileResearching)
        return next new ex.ResetRequired("","postFinishResearchProjectile request - No ammo research")

    startResearchTimestamp = timeutils.clientTimeformatToTimestamp(user.castle.ammoResearch.researchStartTimestamp)

    projectileParams = balconomy.getProjectileParams(user.castle.ammoResearch.projectileId, user.castle.ammoResearch.projectileLevel)

    if(Date.now() < (startResearchTimestamp + projectileParams.researchTime - 30000)) # a little bit offsync allowed
        util.log '[ERROR] postFinishResearchProjectile request - research hasnt finished yet, user '+user.username+'('+user.display_name+')'
        return next new ex.ResetRequired("","postFinishResearchProjectile request - research hasnt finished yet")
        
    if user.finishProjectileResearchImmediately() == false
        util.log '[ERROR] postFinishResearchProjectile request - could not finish ammo research, user '+user.username+'('+user.display_name+')'
        return next new ex.ResetRequired("","Could not finish ammo research")
    
    user.save (err, obj) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postFinishResearchProjectile'
            return next new ex.ResetRequired("","postFinishResearchProjectile user profile save")
        else
            res.json
                status: 'ok'


exports.postFinishProjectile = (req, res, next) ->
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if debugMode
        logAtomicMethodEntry('postFinishProjectile', user, balconomy.getVersion(), req.body.projectileId, req.body.projectileAmount)
    
    if(req.body.projectileId == null)
        util.log '[ERROR] postFinishProjectile request - user send projectileId = null, user '+user.username+'('+user.display_name+')'
        return next new ex.ResetRequired("","postFinishProjectile request - projectile is null")

    if(user.castle.ammoProductionStartTimestamp == '01/01/0001 00:00:00')
        util.log '[ERROR] postFinishProjectile request - projectile isnt being constructed, user '+user.username+'('+user.display_name+')'
        return next new ex.ResetRequired("","postFinishProjectile request - projectile isnt being constructed")

    projectiles = req.body.projectileAmount || 1
    projectileCount = 0

    while projectiles
        projectileCount += 1
        if debugMode
            util.log ' ---------- Finishing projectile ' + req.body.projectileId + ' number ' + projectileCount + '...'
        if (!user.finishProjectileProduction(req.body.projectileId, balconomy))
            util.log '[ERROR] postFinishProjectile request - request fail, user '+ user.username + '('+user.display_name+')'
            return next new ex.ResetRequired("","postFinishProjectile request fail")
        projectiles -= 1

    user.save (err, userProfile) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postFinishProjectile'
            return next new ex.ResetRequired("","postFinishProjectile user profile save")

        res.json
            status: 'ok'

exports.postRemoveProjectile = (req, res, next) ->
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if debugMode
        logAtomicMethodEntry('postRemoveProjectile', user, balconomy.getVersion(), req.body.projectileId, req.body.projectileAmount)
    
    if(req.body.projectileId == null)
        util.log '[ERROR] postRemoveProjectile request - user send projectileId = null, user '+user.username+'('+user.display_name+')'
        return next new ex.ResetRequired("","postRemoveProjectile request - projectile is null")

    projectiles = req.body.projectileAmount || 1
    projectileCount = 0

    while projectiles
        projectileCount += 1
        if debugMode
            util.log ' ---------- Removing projectile ' + req.body.projectileId + ' number ' + projectileCount + '...'
        if (!user.removeProjectile(req.body.projectileId))
            util.log '[ERROR] postRemoveProjectile request - request fail, user '+user.username+'('+user.display_name+')'
            return next new ex.ResetRequired("","postRemoveProjectile request fail")
        projectiles -= 1
        

    user.save (err, userProfile) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postRemoveProjectile'
            return next new ex.ResetRequired("","postRemoveProjectile user profile save")

        res.json
            status: 'ok'

exports.postGetStatistics = (req, res, next) ->
    
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if debugMode
        logAtomicMethodEntry('postGetStatistics', user, balconomy.getVersion(), req.body.userId)
    
    if user._id = req.body.userId
        res.json
            stats: user.stats
    else
        mm.UserProfile.findById req.body.userId, (err, otherUser) ->
            if err?
                util.log '[ERROR] '+ err + ' finding user: '+ user.username + ' on postGetStatistics'
                return next new ex.NotFound req.body.userId
                
            else
                res.json
                    stats: otherUser.stats

exports.postTutorialProgress = (req, res, next) ->
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if debugMode
        logAtomicMethodEntry('postTutorialProgress', user, balconomy.getVersion(), req.body.tutorialState)
    
    if (!user.setTutorialState(req.body.tutorialState))
        util.log '[ERROR] postTutorialProgress request - request fail, user '+user.username+'('+user.display_name+')'
        return next new ex.ResetRequired("","postTutorialProgress request fail")

    user.save (err, userProfile) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postTutorialProgress'
            return next new ex.ResetRequired("","postTutorialProgress user profile save")

        if req.body.tutorialState == 1
            GameInn.SendEvent 'TUTORIAL_END', {userID: userProfile._id}, (err, data) ->
                if err?
                    console.log err

        if req.body.tutorialState == 2
            GameInn.SendEvent 'TUTORIAL_START', {userID: userProfile._id}, (err, data) ->
                if err?
                    console.log err

        res.json
            status: 'ok'

exports.postStoryProgress = (req, res, next) ->
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if debugMode
        logAtomicMethodEntry('postStoryProgress', user, balconomy.getVersion(), req.body.eventId)
    
    if (!user.updateStoryProgressList(req.body.eventId))
        util.log '[ERROR] postStoryProgress request - request fail, user '+user.username+'('+user.display_name+')'
        return next new ex.ResetRequired("","postStoryProgress request fail")

    user.save (err, userProfile) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postStoryProgress'
            return next new ex.ResetRequired("","postStoryProgress user profile save")

        res.json
            status: 'ok'

exports.postCancelAmmoProduction = (req, res, next) ->
    
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if debugMode
        logAtomicMethodEntry('postCancelAmmoProduction', user, balconomy.getVersion(), req.body.projectileId, req.body.projectileAmount)
    
    projectileDefinition = balconomy.getProjectileDefinition(req.body.projectileId)
    projectileLevelParams = balconomy.getProjectileParams(req.body.projectileId, user.getAmmoLevel(req.body.projectileId))

    projectiles = req.body.projectileAmount
    cost = projectileLevelParams.costValue
    type = balconomy.resolveCostCategoryType(projectileDefinition.costCategoryId)
    projectileCount = 0

    while projectiles

        projectileCount += 1
        if debugMode
            util.log ' ---------- Canceling production of projectile ' + req.body.projectileId + ' number ' + projectileCount + '...'
        #return resources to user
        if ( !user.addResourceToStorage(cost, type, balconomy) )
            util.log '[ERROR] postCancelAmmoProduction request - addResourceToStorage resourceType: '+type+' not found'
            return next new ex.ResetRequired("","postCancelAmmoProduction request - returning resources went wrong")
            
        #modify queue
        if ( !user.removeProjectileFromQueue(req.body.indexInProductionQueue) )
            util.log '[ERROR] postCancelAmmoProduction request - removing projectile went wrong, user '+ user.username + '('+user.display_name+')'
            return next new ex.ResetRequired("","postCancelAmmoProduction request - removing projectile went wrong")
        
        projectiles -= 1

    user.save (err, obj) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postCancelAmmoProduction'
            return next new ex.ResetRequired("","postCancelAmmoProduction user profile save")
        else
            if debugMode
                util.log '[postCancelAmmoProduction] Projectile production canceled for user: ' + user.username

            GameInn.SendEvent 'CANCEL_AMMO', {userID: user._id, projectileID: req.body.projectileId, amount: req.body.projectileAmount, resourceType: type, cost: cost * req.body.projectileAmount}, (err, data) ->
                if err?
                    console.log err
            
            res.json
                status: 'ok'

exports.postLastNotificationVisible = (req, res, next) ->
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if debugMode
        logAtomicMethodEntry('postLastNotificationVisible', user, balconomy.getVersion())
    
    if (!user.SetLastNotificationVisible(req.body.timestamp))
        util.log '[ERROR] postLastNotificationVisible request - request fail, user '+ user.username + '('+user.display_name+')'
        return next new ex.ResetRequired("","postLastNotificationVisible request fail")

    user.save (err, userProfile) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postLastNotificationVisible'
            return next new ex.ResetRequired("","postLastNotificationVisible user profile save")

        res.json
            status: 'ok'

exports.ShowLootCart = (req, res, next) ->
    user = req.castle.user

    if debugMode
        logAtomicMethodEntry('ShowLootCart', user, null, req.body.showed)

    showed = req.body.showed
    seenTimestamp = req.body.seenTimestamp

    missing = []

    if not showed?
        missing.push 'showed'
    if not seenTimestamp?
        missing.push 'seenTimestamp'

    if missing.length > 0
        util.log '[ERROR] postLastNotificationVisible request - missing parameters '+missing+', user '+ user.username + '('+user.display_name+')'
        return next new ex.MissingParameters missing

    user.lootCart.lootCartShowed = showed
    user.lootCart.lastLootCartSeenTimestamp = seenTimestamp


    user.save (err, userProfile) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' at ShowLootCart'
            return next new ex.ResetRequired("","ShowLootCart user profile save")

        res.json
            status: 'ok'

exports.postFinishAmmoCommercial = (req, res, next) ->
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if(not req.body.reducedTime?)
        util.log '[ERROR] Missing parameter reducedTime on postFinishAmmoCommercial, user: '+user.username+'('+user.display_name+')'
        return next new ex.ResetRequired("","Missing parameter reducedTime on postFinishAmmoCommercial")

    if debugMode
        logAtomicMethodEntry('postFinishAmmoCommercial', user, balconomy.getVersion())

    reducePercent = balconomy.getAdsReduceProductionTimePercent()
    calculatedReducedProductionTime = user.calculateAmmoProductionRemainTimeInSeconds(balconomy) * reducePercent

    #if(calculatedReducedProductionTime < req.body.reducedTime)
    #    util.log '[ERROR] calculatedReducedProductionTime: '+calculatedReducedProductionTime+', client reducedTime: '+req.body.reducedTime+', user: '+user.username+'('+user.display_name+')'
    #    return next new ex.ResetRequired("","Ads limit reached on postFinishAmmoCommercial")

    if(user.incrementAdsCount(balconomy) == false)
        util.log '[ERROR] Ads limit reached on postFinishAmmoCommercial, user: '+user.username+'('+user.display_name+')'
        return next new ex.ResetRequired("","Ads limit reached on postFinishAmmoCommercial")

    user.finishAmmoCommercial(req.body.reducedTime)
    
    user.save (err, obj) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postFinishAmmoCommercial'
            return next new ex.ResetRequired("","postFinishAmmoCommercial user profile save")
        else
            GameInn.SendEvent 'AD_BOOST', {userID: user._id}, (err, data) ->
                if err?
                    console.log err

            res.json
                status: 'ok'


exports.postFreeGemsCommercial = (req, res, next) ->
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if(user.incrementFreeGemsAdsCount(balconomy) == false)
        util.log '[ERROR] Ads limit reached on postFreeGemsCommercial, user: '+user.username+'('+user.display_name+')'
        return next new ex.ResetRequired("","Ads limit reached on postFreeGemsCommercial")

    user.addFreeGemsCommercial(balconomy)
    
    user.save (err, obj) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postFreeGemsCommercial'
            return next new ex.ResetRequired("","postFreeGemsCommercial user profile save")
        else
            GameInn.SendEvent 'AD_RUBY', {userID: user._id, hard: balconomy.getFreeGemsAdsReward()}, (err, data) ->
                if err?
                    console.log err

            res.json
                status: 'ok'

exports.postCollectAchievement = (req, res, next) ->
    user = req.castle.user
    balconomy = req.app.castle.balconomy
    achievementId = req.body.achievementId
    reward = req.body.reward
    step = req.body.step

#    console.log 'achievementId ' + achievementId
#    console.log 'reward ' + reward
#    console.log 'step ' + step

    if not (achievementId? and reward? and step?)
        missing = ['achievementId', 'reward', 'step']
        util.log '[ERROR] postCollectAchievement request - missing parameters '+missing+', user '+ user.username + '('+user.display_name+')'
        return next new ex.MissingParameters missing

    achievementParams = balconomy.getAchievement achievementId
#    console.log JSON.stringify achievementParams

    achievement = user.getAchievement achievementId
    if not (achievementParams and achievement)
        return next new ex.InternalServerError "Cannot find achievement"

    predictedReward = 0

    for stepValue, stepIndex in achievementParams.step
        if step == stepIndex and achievement.currentProgress >= stepValue
            if achievement.lastCollectedReward < stepIndex
                achievement.lastCollectedReward = stepIndex
                predictedReward += achievementParams.reward[stepIndex]

    if predictedReward != reward
        return next new ex.ResetRequired("","predicted reward for achievement does not match", {reward: reward, predicted: predictedReward, achievementId: achievementId})

    user.addHard reward

    user.save (err, obj) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postCollectAchievement'
            return next new ex.ResetRequired("","postCollectAchievement user profile save")
        else
            GameInn.SendEvent 'COLLECT_RESOURCES', {userID: user._id, achievementId: achievementId, resources: [{type: 'RUBY', amount: reward, location: 'ACHIEVEMENT'}]}, (err, data) ->
                if err?
                    console.log err

            res.json
                status: 'ok'

exports.postRefillResources = (req, res, next) ->
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if(user.IsTutorialOn())
        user.refillResources(balconomy)

        user.save (err, obj) ->
            if err?
                util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postRefillResources'
                return next new ex.ResetRequired("","postRefillResources user profile save")
            else
                res.json
                    status: 'ok'
    else
        util.log '[ERROR] User is not in tutorial state - postRefillResources'
        return next new ex.ResetRequired("","User is not in tutorial state - postRefillResources")

exports.getTopGlobalPlayers = (req, res, next) ->
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    mm.UserProfile.find({profileType: 'PLAYER'}).select('stats trophies display_name').sort({trophies: -1}).limit(200).exec (err, users) ->
        if(err?)
            return next err

        view = new mv.Leaderboard(users)
        view.export (err, leaderboardView) ->
            if(err?)
                return next err

            res.json
                leaderboard: leaderboardView

exports.getLeague = (req, res, next) ->
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    mm.League.findOne({ownerId: user._id}).exec (err, league) ->
        if(err?)
            return next err

        userLeagueLevel = balconomy.getRankLevel(user.trophies)

        if(league?)
            if(league.leagueLevel == userLeagueLevel)
                # console.log 'get league'
                league.getLeagueList user, balconomy, (err, leagueView) ->
                    if(err?)
                        return next err

                    res.json
                        leaderboard: leagueView

            else
                GameInn.SendEvent 'LEAGUE_LEVEL_CHANGE', {userID: user._id, lastLeagueLevel: league.leagueLevel, newLeagueLevel: userLeagueLevel}, (err, data) ->
                    if err?
                        console.log err

                # console.log 'update league'
                league.updateLeagueLevel userLeagueLevel, balconomy, (err, updatedLeague) ->
                    if(err?)
                        return next err

                    updatedLeague.getLeagueList user, balconomy, (err, leagueView) ->
                        if(err?)
                            return next err

                        res.json
                            leaderboard: leagueView

        else
            # console.log 'create league'
            mm.League.createLeague user, userLeagueLevel, balconomy, (err, createdLeague) ->
                if(err?)
                    return next err

                createdLeague.getLeagueList user, balconomy, (err, leagueView) ->
                    if(err?)
                        return next err

                    res.json
                        leaderboard: leagueView

exports.postFreeTutorialAmmo = (req, res, next) ->
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if(!req.body.projectileId?)
        return next new ex.ResetRequired("","postFreeTutorialAmmo missing parameter projectileId")

    if(!req.body.amount?)
        return next new ex.ResetRequired("","postFreeTutorialAmmo missing parameter amount")
    

    if(user.IsTutorialOn())
        user.AddProjectile(req.body.projectileId, req.body.amount)

        user.save (err, obj) ->
            if err?
                util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on postFreeTutorialAmmo'
                return next new ex.ResetRequired("","postFreeTutorialAmmo user profile save")
            else
                res.json
                    status: 'ok'
    else
        util.log '[ERROR] User is not in tutorial state - postFreeTutorialAmmo'
        return next new ex.ResetRequired("","User is not in tutorial state - postFreeTutorialAmmo")

exports.postClanEmail = (req, res, next) ->
    user = req.castle.user

    #server doesnt send status 4XX, to do not clear request queue
    if(!req.body.email?)
        res.json
            status: 'error'
    
    else
        user.email = req.body.email
        user.save (err, obj) ->
            if(err?)
                res.json
                    status: err

            else
                res.json
                    status: 'ok'

exports.tutorialCheck = (req, res, next) ->
    user = req.castle.user
    mm.FightHistory.getTutorialBattleState user._id, (err, state) ->
        if err?
            return next new ex.InternalServerError

        res.json
            status: 'ok'
            tutorialFinished: state

exports.postUserRateApp = (req, res, next) ->
    user = req.castle.user

    user.didUserRateThisApp = true
    user.save (err, obj) ->
        if(err?)
            res.json
                status: err

        else
            res.json
                status: 'ok'

logExpressiveTimeInfo = (servertimestamp, clientrequest) ->
   if debugMode
       util.log 'client sent string: ' + clientrequest + ', which is timestamp: ' + timeutils.clientTimeformatToTimestamp(clientrequest)
       util.log 'server time is:     ' + timeutils.timestampToClientTimeformat(servertimestamp) + ', which is timestamp: ' + servertimestamp
       util.log '----------------- client request came ' + ( ( servertimestamp - timeutils.clientTimeformatToTimestamp(clientrequest) ) / 1000.0) + ' seconds later -----'


logAtomicMethodEntry = (method, user, balconomy, subject, amount) ->
   if debugMode
       logMessage = '[Atomic Method: ' + method + '] User: ' + user.username + ' (' + user.display_name + ')'
       if balconomy?
           logMessage += ', Balconomy: ' + balconomy
       if subject?
           logMessage += ', about: ' + subject
       if amount?
           logMessage += ', amount: ' + amount
           
       util.log logMessage