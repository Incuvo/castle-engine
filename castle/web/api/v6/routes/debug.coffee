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

rand = require '../../../util/rand'
oauth = require './oauth'
time = require '../../../util/time'




exports.debugChangeCastle = (req, res, next) ->
    if not req.body.definitionType?
        return next new ex.MissingParameters ['definitionType']
    else
        mm.DefinitionCastle.findOne {definitionType: req.body.definitionType}, (err, castle) ->
            if err?
                util.log '[WARN] Cannot find definition castle ' + err + ' at debugChangeCastle'
                return next new ex.NotFound req.body.definitionType
            if castle == null
                return next new ex.NotFound req.body.definitionType
            req.castle.user.castle = castle
            req.castle.user.save (err, user) ->
                return next new ex.ResetRequired "DEBUG_RESET", "DEBUG_PROFILE_CHANGE_RESET"

exports.getBalconomy = (req, res, next) ->
    if(req.query.version == null)
        res.json
            balconomy: req.app.castle.balconomy
    else
        mm.Balconomy.findOne({'version': req.query.version}, (err, bal) ->
            if err?
                util.log '[WARN] Cannot find balconomy version ' + req.query.version + ' ' + err
                return next err

            res.json
                balconomy: bal
        )

exports.postBalconomy = (req, res, next) ->
    if(req.body.balconomy == null)
        res.json
            status: 'no balconomy send'
    else
        mm.Balconomy.findOne {'version': req.body.balconomy.version}, (err, balconomy) ->
            if err?
                util.log '[ERROR] Cannot find balconomy at develop postBalconomy ' + err
                return next err

            if balconomy?
                mm.Balconomy.remove {'version': req.body.balconomy.version}, (err, balconomy)->
                    if err?
                        util.log '[ERROR] Cannot remove balconomy at develop postBalconomy ' + err
                        return next err

                    mm.Balconomy.create(
                        req.body.balconomy
                    ,(err, doc) ->
                        if err?
                            util.log '[ERROR] Cannot create balconomy ' + err
                            return next err
                        req.app.castle.pub.publish 'BALCONOMY', "OnBalconomyCHange"
                        mm.UserProfile.update {}, {$set:{resetRequired:true, resetMessage: 'RESET_BALCONOMY'}}, {multi:true}, (err, doc) ->
                            if err?
                                util.log '[ERROR] When updating users at postBalconomy ' + err
                                return next err

                            res.json
                                status: 'ok'
                    )
            else
                mm.Balconomy.create(
                    req.body.balconomy
                ,(err, doc) ->
                    if err?
                        util.log '[ERROR] Cannot create balconomy 2 ' + err
                        return next err
                    req.app.castle.pub.publish 'BALCONOMY', "OnBalconomyCHange"
                    mm.UserProfile.update {}, {$set:{resetRequired:true, resetMessage: 'RESET_BALCONOMY'}}, {multi:true}, (err, doc) ->
                        if err?
                            util.log '[ERROR] When updating users at postBalconomy 2 ' + err
                            return next err

                        res.json
                            status: 'ok'
                )

exports.RemoveProjectiles = (req, res, next) ->
    user = req.castle.user

    user.castle.ammoStoredList = []

    user.save (err, userProfile) ->
        if err?
            util.log '[UserProfile] Error: '+ err + ' saving user: '+ user.username + ' on RemoveProjectiles'
            return next new ex.ResetRequired("","RemoveProjectiles user profile save")

        res.json
            status: 'ok'

exports.AddProjectiles = (req, res, next) ->
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    ammoLevelsList = user.castle.ammoLevelsList

    for ammoLevel in ammoLevelsList
        user.AddProjectile ammoLevel.projectileId, 10

    user.save (err, userProfile) ->
        if err?
            util.log '[UserProfile] Error: '+ err + ' saving user: '+ user.username + ' on AddProjectiles'
            return next new ex.ResetRequired("","AddProjectiles user profile save")

        res.json
            status: 'ok'

exports.UpgradeProjectiles = (req, res, next) ->
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    level = 0
    for proj in user.castle.ammoLevelsList
        if proj.projectileLevel == balconomy.getProjectileMaxLevel proj.projectileId
            continue
        proj.projectileLevel++
        level = proj.projectileLevel

    for stored in user.castle.ammoStoredList
        stored.projectileLevel = level

    user.save (err, userProfile) ->
        if err?
            util.log '[UserProfile] Error: '+ err + ' saving user: '+ user.username + ' on UpgradeProjectiles'
            return next new ex.ResetRequired("","UpgradeProjectiles user profile save")

        res.json
            status: 'ok'

exports.DowngradeProjectiles = (req, res, next) ->
    user = req.castle.user

    level = 0
    for proj in user.castle.ammoLevelsList
        if proj.projectileLevel == 1
            continue
        proj.projectileLevel--
        level = proj.projectileLevel

    for stored in user.castle.ammoStoredList
        if level == 0
            continue
        stored.projectileLevel = level

    user.save (err, userProfile) ->
        if err?
            util.log '[UserProfile] Error: '+ err + ' saving user: '+ user.username + ' on UpgradeProjectiles'
            return next new ex.ResetRequired("","UpgradeProjectiles user profile save")

        res.json
            status: 'ok'

exports.AddGems = (req, res, next) ->
    user = req.castle.user
    amount = if req.body.amount? then req.body.amount else 5000


    user.addHard(amount)
    user.save (err, userProfile) ->
        if err?
            util.log '[UserProfile] Error: '+ err + ' saving user: '+ user.username + ' on AddGems'
            return next new ex.ResetRequired("","AddGems user profile save")

        res.json
            status: 'ok'

exports.debugTest = (req, res, next) ->
    util.log JSON.stringify req.app.castle.balconomy.getProjectileDefinitions()

    res.json
        status: 'ok'

exports.checkErrors = (req, res, next) ->
    mm.Error.find {}, (err, errorRecords) ->
        if err?
            next new ex.InternalServerError 'Couldnt get errors from server'

        res.json
            errors: errorRecords

exports.debugBuyRoom = (req, res, next) ->

    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if debugMode
        logAtomicMethodEntry('postBuyRoom', user, balconomy.getVersion(), req.body.roomType, req.body.clientBuilidingStartTimestamp)

    clientBuildingStartTimestamp = timeutils.clientTimeformatToTimestamp(req.body.clientBuilidingStartTimestamp)
    serverCompareTimestamp = Date.now() - 30000

    if debugMode
        logExpressiveTimeInfo(serverCompareTimestamp + 30000, req.body.clientBuilidingStartTimestamp)

    roomParams = balconomy.getRoomParams(req.body.roomType, 1)


    #: this request needs to have coordinates for room given in a request body! This should ensure right castle mapping on the server
    user.addBuildRoom(balconomy.resolveRoomId(req.body.roomType), req.body.roomType, req.body.xPosition, req.body.yPosition, clientBuildingStartTimestamp, clientBuildingStartTimestamp + roomParams.constructionTime * 1000)

    user.save (err, userProfile) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' on PostBuyRoom'
            return next new ex.ResetRequired("","PostBuyRoom user profile save")

        res.json
            status: 'ok'

exports.checkPurchase = (req, res, next) ->

    gem =
        gemspack1: 0.99
        gemspack2: 4.99
        gemspack3: 9.99
        gemspack4: 19.99
        gemspack5: 49.99
        gemspack6: 99.99

    if not req.body.token?
        return next new ex.URINotFound

    if req.body.token != 'kamimamifamilami2048'
        return next new ex.URINotFound

    mm.Purchase.find({purchaseStatus: 'COMPLETED'}).populate('user').sort({user: -1}).exec (err, purchases) ->

        if err?
            console.log err
            return next new ex.InternalServerError 'Nie znalazł pieniążka ;('

        data = {}

        for purchase in purchases
            price = gem[purchase.receipt.productId]
            userId = purchase.user.username
            date = '[' + time.timestampToClientTimeformat(purchase.created) + ']'
            if data[userId]
                data[userId].buyCount++
                data[userId].sum += price
                data[userId].purchases += ' ' + date
            else
                data[userId] =
                    buyCount: 1
                    sum: price
                    name: purchase.user.display_name
                    purchases: date
                    mongo: purchase.user._id

        printString = ''

        for userId, userData of data
            printString += userData.mongo + ', ' + userData.name + ', ' + userId + ', ' + userData.sum + ', ' + userData.buyCount + ', ' + userData.purchases + '\n'
#            data += purchase.user.username + ', ' + purchase.user.display_name + ', ' +  purchase.receipt.productId + '\n'

        res.send printString

exports.checkRetention = (req, res, next) ->

    if not req.body.token?
        return next new ex.URINotFound

    if req.body.token != 'kamimamifamilami2048'
        return next new ex.URINotFound

    if not req.body.mongo?
        return next new ex.URINotFound

    mm.RetentionHistory.find {user: req.body.mongo}, (err, retention) ->

        if err?
            console.log err
            return res "ERROR"

        printString = ''
        for row in retention
            start = time.timestampToClientTimeformat(row.game.start)
            end = time.timestampToClientTimeformat(row.game.end)
            printString += row.user + ', ' + row.game.number + ', ' + start + ', ' + end + ', ' + (row.game.end - row.game.start) / 1000 + '\n'

        res.send printString

exports.checkAttackFights = (req, res, next) ->
    if not req.body.token?
        return next new ex.URINotFound

    if req.body.token != 'kamimamifamilami2048'
        return next new ex.URINotFound

    if not req.body.mongo?
        return next new ex.URINotFound

    mm.FightHistory.find {attacker: req.body.mongo}, (err, fights) ->

        if err?
            console.log err
            return res "ERROR"



        printString = ''
        for row in fights
            date = time.timestampToClientTimeformat(row.timestamp)
            printString += row.attacker + ', ' + row.defender + ', ' + date + ', ' + row.attackerEarn + ', ' + row.percent + ', ' + row.stars + ', ' + row.revenge + '\n'

        res.send printString

exports.iapVerify = (req, res, next) ->
    productId = req.body.inAppId

    addGemsPackAndSendResponse = (valid, data, status) ->
        if valid and productId?
            pack = req.app.castle.balconomy.getInAppPack(productId)
            if (pack.InAppID.indexOf('builderpack') > -1)
                req.castle.user.addRawRoom 'builder', 'BUILDER', 1
            if (req.castle.user.addHard(pack.Value, 0))
                req.castle.user.save (err, userProfile) ->
                    if err?
                        util.log '[UserProfile] Error: '+ err + ' saving user: '+ user.username + ' on iapVerify'
                        return next new ex.ResetRequired("","iapVerify user profile save")

                    res.json
                        valid: valid
                        data: data
                        status: status
            else
                util.log '[ERROR] Couldnt add gems pack  ' + err
                return next new ex.ResetRequired("","iapVerify add gems pack")
        else
            res.json
                valid: valid
                data: data
                status: status

    addGemsPackAndSendResponse(true, {}, "ok")

exports.prepareDefenceFightHistory = (req, res, next) ->
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    mm.UserProfile.aggregate([{"$match": {$and: [{"display_name": {$ne: ''}}, {profileType: 'PLAYER'}]}}, {$sample: {size: 1}}]).exec (err, users) ->
        if(err?)
            return next err

        if(users.length > 0)
            enemy = users[0]

            resourceStealingRatesMultiplierParams = balconomy.getResourceStealingRatesMultiplier(user.getThroneLevel())

            resourceStealingRatesMultiplier = 1
            if(resourceStealingRatesMultiplierParams != null)
                resourceStealingRatesMultiplier = resourceStealingRatesMultiplierParams.multiplier

            fightHistoryObject = {
                attacker: enemy._id
                defender: user._id
                timestamp: Date.now()
                ammoList: []
                attackerTrophies: enemy.trophies
                defenderTrophies: user.trophies
                attackerEarn: 0
                defenderEarn: 0
                resourcesList: []
                destroyedRoomsList: []
                stars: Math.round(Math.random() * 3)
                percent: 0
                replay: null
                isBattleEnd: true
            }

            #percent
            if(fightHistoryObject.stars == 0)
                fightHistoryObject.percent = Math.round(Math.random() * 50)

            else if(fightHistoryObject.stars == 3)
                fightHistoryObject.percent = 100

            else
                fightHistoryObject.percent = Math.round(Math.random() * 50) + 45

            #resources
            if(fightHistoryObject.stars > 0)
                goldLimit = mv.UserProfile.getUserResourceToStealSum(user, 'gold', balconomy) * resourceStealingRatesMultiplier
                manaLimit = mv.UserProfile.getUserResourceToStealSum(user, 'mana', balconomy) * resourceStealingRatesMultiplier
                goldEarned = 0
                manaEarned = 0

                if(fightHistoryObject.stars == 3)
                    goldEarned = goldLimit
                    manaEarned = manaLimit

                else
                    goldEarned = Math.round(Math.random() * goldLimit)
                    manaEarned = Math.round(Math.random() * manaLimit)

                fightHistoryObject.resourcesList.push({resourceType: "GOLD", quantity: goldEarned})
                fightHistoryObject.resourcesList.push({resourceType: "MANA", quantity: manaEarned})

            #projectiles
            ammoUsed = Math.round(Math.random() * 10) + 1

            for projectile in enemy.castle.ammoLevelsList
                if(ammoUsed > 0)
                    ammoCount = Math.round(Math.random() * ammoUsed)

                    if(ammoCount > 0)
                        fightHistoryObject.ammoList.push({projectileAmount: ammoCount, projectileLevel: projectile.projectileLevel, projectileId : projectile.projectileId})
                        ammoUsed -= ammoCount

            #trophies
            EarnTrophies = 1
            
            if(fightHistoryObject.stars == 0)
                fightHistoryObject.defenderEarn = EarnTrophies

            else
                fightHistoryObject.attackerEarn = EarnTrophies + fightHistoryObject.stars
                fightHistoryObject.defenderEarn = -fightHistoryObject.attackerEarn
            
            mm.FightHistory.create fightHistoryObject, (err, fightHistory) ->
                if (err)
                    return next err

                mm.FightHistory.find({$or: [{attacker: req.castle.user._id}, {defender: req.castle.user._id}]}, null, {sort:{timestamp: -1}}).populate('attacker').populate('defender').exec (err, fightList) ->
                    if (err)
                        return next err

                    user = req.castle.user
                    balconomy = req.app.castle.balconomy

                    fights = []
                    attackerFightCount = 0
                    defenderFightCount = 0

                    for fight in fightList
                        if fight.attacker._id.toString() == user._id.toString()
                            if attackerFightCount < balconomy.getFightHistoryLimit()
                                attackerFightCount += 1
                                fights.push(fight)

                        else if fight.defender._id.toString() == user._id.toString()
                            if defenderFightCount < balconomy.getFightHistoryLimit()
                                defenderFightCount += 1
                                fights.push(fight)

                        if((attackerFightCount == balconomy.getFightHistoryLimit()) and (defenderFightCount < balconomy.getFightHistoryLimit()))
                            break

                    view = new mv.FightHistory(fights, req.app.castle.config)
                    res.json
                        fights: view.export()


        else
            mm.FightHistory.find({$or: [{attacker: req.castle.user._id}, {defender: req.castle.user._id}]}, null, {sort:{timestamp: -1}}).populate('attacker').populate('defender').exec (err, fightList) ->
                if (err)
                    return next err

                user = req.castle.user
                balconomy = req.app.castle.balconomy

                fights = []
                attackerFightCount = 0
                defenderFightCount = 0

                for fight in fightList
                    if fight.attacker._id.toString() == user._id.toString()
                        if attackerFightCount < balconomy.getFightHistoryLimit()
                            attackerFightCount += 1
                            fights.push(fight)

                    else if fight.defender._id.toString() == user._id.toString()
                        if defenderFightCount < balconomy.getFightHistoryLimit()
                            defenderFightCount += 1
                            fights.push(fight)

                    if((attackerFightCount == balconomy.getFightHistoryLimit()) and (defenderFightCount < balconomy.getFightHistoryLimit()))
                        break

                view = new mv.FightHistory(fights, req.app.castle.config)
                res.json
                    fights: view.export()