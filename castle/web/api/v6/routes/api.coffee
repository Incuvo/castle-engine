# Defines API endpoints.
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
mv = require '../model-views'
moment    = require 'moment'
profanity = require '../../../util/profanity'
hashids   = require 'hashids'

xml2js    = require('xml2js')
zlib      = require('zlib')

onesignal = require '../onesignal'

rand = require '../../../util/rand'
generalUtil = require '../../../util/general'
oauth = require './oauth'
test = require '../test-profile'
timeutils = require '../../../util/time'
GameInn = require './../../../../../GameInn/index.js'
GeoQuery = require './../../../../../GeoQuery/geoquery.js'

ValidationError = mongoose.Document.ValidationError
ObjectId = mongoose.Types.ObjectId
config = require './version'


exports.initGame = (req, res, next) ->

    if req.body.username? and req.body.password? and req.body.username != "" and !req.body.password != ""
        oauth.oauth req, res, next

    else
        createUser req, res, next

createUser = (req, res, next) ->
    mm.Persistent.findOneAndUpdate {}, {$inc:{nid:1}}, {new:true}, (err, persistentRecord) ->
        if err?
            return new ex.InternalServerError()
        persistentRecordJson = persistentRecord.toJSON()
        nid = persistentRecordJson.nid
        cache = req.app.castle.cache
        originKey = (req.headers['x-forwarded-for'] || req.connection.remoteAddress) + req.headers['x-app-inner-hash']
        cache.get originKey, (err, data) ->
            if data? and data == "1"
                cache.setex originKey, 1, '1'
                return next new ex.Forbidden

            userObj = {}

            device_token = req.body.device_token || ''
            lang = req.headers['lang'] || 'en'
            plat = req.headers['x-plat'] || 'any'
            ip_address = req.headers['x-forwarded-for'] || req.connection.remoteAddress

            cache.setex originKey, 2, '1'

            userObj['roles'] = ['user']
            mm.DefinitionAchievement.find {}, (err, achievementDefinition) ->
                if err?
                    return next err

                mm.DefinitionCastle.find {definitionType: /DEFAULT/}, (err, castleDefinition) ->
                    if err?
                        return next err

                    castleIndex = rand.randomRange(0, castleDefinition.length)

                    userObj['castle'] = generalUtil.excludeFromObject castleDefinition[castleIndex].toObject(), ['_id']
                    userObj['achievements'] = achievementDefinition

                    password = crypto.randomBytes(20).toString('hex')

                    userObj['nid'] = nid
                    userObj['username'] = "Player" + userObj.nid
                    userObj['email'] = userObj.nid + "@emptyemail.org"
                    userObj['password'] = password
                    userObj['cloud'] = [1, 2]
                    userObj['currency'] = {
                        hard: 300
                        hardSpent: 0
                        hardBonus: 0
                    }
                    userObj['info'] = {
                        lang:lang
                        plat:plat
                        device_token : device_token
                        last_ip : ip_address
                    }
                    #set display name for fake account generated from generate.sh
                    if req.body.display_name
                        userObj['display_name'] = req.body.display_name
                        userObj['currentTutorialState'] = 1
                        userObj['fakeAccount'] = true
                        createRetention = false
                    else
                        #create retentionHistory for user
                        createRetention = true

                    GeoQuery.geoquery {ip: ip_address}, (err, data) ->
                        if err?
                            console.log '[Create User GeoQuery Error] '+err
                            userObj['info']['timezone'] = 0;
                        else
                            userObj['info']['timezone'] = data.diff;

                        mm.UserProfile.create userObj, (err, user) ->
                            if err?
                                if err instanceof ValidationError
                                    return next new ex.ValidationError (new mv.UserProfile(user)).getErrorMessages(err.errors)
                                else
                                    if err and err.code and err.code == 11000
                                        util.log '[ERROR] Creating user with duplicate key in mongo'
                                        return next new ex.InternalServerError '666'

                                return next err

                            if (createRetention)
                                mm.RetentionHistory.create {
                                    user: user._id
                                    game: {
                                        start: Date.now()
                                        end: null
                                        number: 1
                                    }

                                }, (err, retentionHistory) ->
                                    if err?
                                        return next err

                                    # now using fillMap is only when retention is created

                                    user.fillMap req.app.castle.balconomy, true, (user) ->
                                        GameInn.SendEvent 'CREATE_USER', {userID: user._id}, (err, data) ->
                                            if err?
                                                console.log err
                                                
                                        res.status(201).json {
                                            access_token: user.access_token
                                            password: password
                                            user: (new mv.UserProfile(user, {balconomy: req.app.castle.balconomy, user: user})).export()
                                            balconomy: req.app.castle.balconomy.get()
                                            ts: Date.now()
                                        }
                            else
                                user.fillMap req.app.castle.balconomy, true, (user) ->
                                    GameInn.SendEvent 'CREATE_USER', {userID: user._id}, (err, data) ->
                                        if err?
                                            console.log err

                                    res.status(201).json {
                                        access_token: user.access_token
                                        password: password
                                        user: (new mv.UserProfile(user, {balconomy: req.app.castle.balconomy, user: user})).export()
                                        balconomy: req.app.castle.balconomy.get()
                                        ts: Date.now()
                                    }

exports.userUpdate = (req, res, next) ->
    if req.params.id != 'me'
        return next new ex.Forbidden

    userObj = req.body
    excludedUpdateFields = [
        '_id',
        'version',
        'appVersion',
        'username',
        'email',
        'password',
        'joined',
        'roles',
        'flags',
        'last_profile_data_update',
        'last_user_activity',
        'trophies',
        'level',
        'map',
        'stats',
#        Currently commented out but should be respected in future !
#        'currency',
        'timers'
    ]
    test.testProfile userObj, req.castle.user

    userObj = generalUtil.excludeFromObject userObj, excludedUpdateFields

    res.json
        status: 'ok'
#    mm.UserProfile.update {username: req.castle.user.username}, {$set: userObj}, (err, update) ->
#        if err?
#            util.log err + ' in updating userProfile'
#            return next err
#
#        res.json
#            update: update
    


exports.usersStats = (req, res, next) ->
    async.parallel {
        usersTotal: (cb) ->
            mm.UserProfile.find().count cb
    }, (err, results) ->
        if err?.length not in [undefined, 0]
            util.log err
            return next new Error 'Failed to generate users stats'

        res.json
            users:
                total: results.usersTotal


exports.getServerTime = (req, res, next) ->
    #util.log '[getServerTime]: ' + Date.now() + 'which should be ' + timeutils.timestampToClientTimeformat(Date.now())
    res.json
        ver: config.api.version
        ts : Date.now()

exports.getPromoTime = (req, res, next) ->
    mm.ServerConfig.findOne {created : true}, (err, serverConfig) ->
        if err
            res.json
                ts: Date.now() - 10000
        else
            res.json
                ts: serverConfig.promo_date



#exports.iapVerifyORIGINAL = (req, res, next) ->
#
#    receiptRaw = new Buffer(req.query.receipt, 'base64')
#
#    req.app.castle.iap.verifyAutoRenewReceipt receiptRaw, (valid, msg, data) ->
#
#        if not valid and msg == "json_parse_error"
#
#            util.log "[iapVerify] [json_parse_error:#{data}] [receipt:#{req.query.receipt}] [user#{req.castle.user.username}]"
#
#            res.json
#                valid: true
#                msg: msg
#                data: {}
#
#            return
#
#        if data and data.receipt and data.receipt.bid and data.receipt.bid.indexOf('com.Incuvo.Castle') != -1
#
#            mm.Purchase.create {
#                user: req.castle.user._id
#                receipt: data.receipt
#            }, (err, receiptLog) ->
#
#                if err?
#                    util.log """
#                     [MongoDB] [err:#{err}] Failed to log iap receipt
#                      user:#{req.castle.user._id} and receipt:#{data.receipt}
#                    """
#            res.json
#                valid: valid
#                msg: msg
#                data: data
#        else
#            res.json
#                valid: false
#                msg: msg
#                data: data

exports.iapVerify = (req, res, next) ->
    plat = req.headers['x-plat']
    iap = req.app.castle.iapService
    receiptRaw = req.body.receipt

    savePurchase = (receipt, status = '', reason = '') ->
        saveDate =
            plat : plat
            user: req.castle.user._id
            receipt: receipt

        if status != ''
            saveDate['purchaseStatus'] = status
        if reason != ''
            saveDate['reason'] = reason

        mm.Purchase.create saveDate, (err, receiptLog) ->
            if err?
                util.log '[ERROR] when saving purchase ' + plat + ' userId ' + userId + ' receipt ' + receipt

            if status != ''
                util.log '[WARN] Invalid in app purchase ' + JSON.stringify receipt

    addGemsPackAndSendResponse = (valid, data, status) ->
        if valid
            if plat == 'AGP'
                productId = data.productId
            else
                productId = data.receipt.in_app[0].product_id

            GameInn.SendEvent 'SHOP_PURCHASE', {userID: req.castle.user._id, productID: productId}, (err, data) ->
                    if err?
                        console.log err

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

    if not receiptRaw
        util.log '[WARN] Receipt raw empty'
        savePurchase('', 'ISSUE_NO_RECEIPT', 'Receipt not found')
        return addGemsPackAndSendResponse false, {}, 'ISSUE_NO_RECEIPT'

    if plat == "AGP"
        iapValidationType = iap.GOOGLE
    else if (plat != "IOS" and plat != 'IPhonePlayer')
        util.log '[WARN] unknown platform ' + plat
        savePurchase(receiptRaw, 'ISSUE_UNKNOWN_PLATFORM', 'No ios or android detected')
        return addGemsPackAndSendResponse false, {}, 'ISSUE_UNKNOWN_PLATFORM'



    if plat == "AGP"
        if not (receiptRaw and receiptRaw.data)
            util.log '[WARN] Receipt raw data field empty'
            savePurchase(receiptRaw, 'ISSUE_NO_RECEIPT_DATA', 'Receipt field data not found')
            return addGemsPackAndSendResponse false, {}, 'ISSUE_NO_RECEIPT_DATA'

        receiptRaw.data = (new Buffer(receiptRaw.data, 'base64')).toString()
    else
        receiptRaw = new Buffer(receiptRaw, 'base64')

    if plat == "AGP"
        iap.validate iapValidationType, receiptRaw, (err, validationResult) ->
            if err?
                util.log '[ERROR] ' + err.toString()
                util.log 'this is the error'
                util.log '[INFO] ' + validationResult
                if err.toString().indexOf('failed to validate') != -1
                    savePurchase(validationResult, 'ISSUE_VALID', err.toString())
                    return addGemsPackAndSendResponse(false, {}, err.toString())
                else
                    savePurchase(validationResult, 'ISSUE_VALID', err)
                    return addGemsPackAndSendResponse false, {}, 'ISSUE_VALID'

            if iap.isValidated(validationResult)
                mm.Purchase.find {'receipt.purchaseToken': validationResult.purchaseToken}, (err ,purchase) ->
                    if err?
                        util.log '[ERROR] Finding purchase ' + err + ' '
                        addGemsPackAndSendResponse(false,{} ,"INTERNAL_ERROR")
                    else if purchase? and purchase.length > 0
                        util.log '[ERROR] Purchase token exists in db'
                        savePurchase(validationResult, 'DUPLICATE', 'Purchase token exists in db')
                        addGemsPackAndSendResponse(false,{} ,"TRANSACTION_WAS_DONE_BEFORE")
                    else
                        savePurchase(validationResult)
                        addGemsPackAndSendResponse(true, validationResult, "ok")
            else
                util.log '[WARN] Is validated resulted false '
                savePurchase(validationResult, 'ISSUE_VALID', 'Receipt not valid')
                addGemsPackAndSendResponse(false,{} ,"ISSUE_VALID")
    else
        req.app.castle.iap.verifyAutoRenewReceipt receiptRaw, (valid, msg, data) ->
            # util.log "verify completed"
            if msg == "json_parse_error"
                savePurchase(receiptRaw, 'ISSUE_VALID', valid)
                return addGemsPackAndSendResponse(false, {}, 'ISSUE_VALID')

            if not valid
                savePurchase(receiptRaw, 'ISSUE_VALID', valid)
                return addGemsPackAndSendResponse(false, {}, 'ISSUE_VALID')

            if data and data.receipt and data.receipt.bundle_id and data.receipt.bundle_id.indexOf('com.Incuvo.CastleRevenge') != -1
                # util.log "verify DATA"
                savePurchase(data)
                addGemsPackAndSendResponse(valid, data ,"ok")
            else
                util.log "SOMETHING GOES WRONG"
                util.log JSON.stringify data, null, 2




exports.profanityCheck = (req, res, next) ->
    res.json { valid : profanity.hasSwearWords req.body.text, req.headers['lang'] }


exports.profanityCheck2 = (req, res, next) ->
    res.json { valid : profanity.hasSwearWords2 req.body.text, req.headers['lang'] }

exports.refreshMap = (req, res, next) ->
    mm.UserProfile.findById req.castle.user.valueOf(), (err, user) ->
        user.fillMap req.app.castle.balconomy, false, (userWithMap) ->
            mm.UserProfile.findById(userWithMap._id).populate('map.user').exec (err, user) ->
                view = new mv.UserProfile(user, {balconomy: req.app.castle.balconomy, user: user})
                res.json
                    map: view.exportMap()
                    lootCart:
                        goldInLootCart: user.lootCart.goldInLootCart
                        manaInLootCart: user.lootCart.manaInLootCart
                        lastLootCartCollectedTimestamp: user.lootCart.lastLootCartCollectedTimestamp


exports.uncoverCloud = (req, res, next) ->
    cloudId = parseInt req.body.id

    user = req.castle.user
    balconomy = req.app.castle.balconomy

    if user.isCloudUncovered(cloudId)
        util.log '[ERROR] cloud is uncovered at uncoverCloud'
        return next new ex.ResetRequired("","UncoverCloud request - cloud is uncovered")

    price = balconomy.calculateCloudPricesCurveDesc(cloudId)

    # check with 10% error
    if(req.body.goldPrice < (price * 0.9))
        return next new ex.ResetRequired("","UncoverCloud request - cloud is uncovered")

    if(!user.removeResourceFromStorage(req.body.goldPrice, 'GOLD'))
        return next new ex.ResetRequired("","UncoverCloud request - not enough resources")

    user.uncoverCloud(cloudId)
    user.setAchievementProgress 'achivVoyager', user.cloud.length

    GameInn.SendEvent 'UNCOVER_CLOUD', {userID: user._id, cost: req.body.goldPrice}, (err, data) ->
        if err?
            console.log err

    user.save (err, userProfile) ->
        if err?
            util.log '[ERROR] '+ err + ' saving user: '+ user.username + ' at uncoverCloud'
            return next new ex.ResetRequired("","UncoverCloud user profile save")

        res.json
            status: 'ok'

exports.findNewPlayer = (req, res, next) ->
    user = req.castle.user
    balconomy = req.app.castle.balconomy

    cost = balconomy.getFindNewPlayerCost()

    if(!user.removeHard(cost))
        return next new ex.ResetRequired("","findNewPlayer request - not enough Ruby")

    excludedIds = user.getMapUserIds()
    excludedIds.push user._id

    # : Change to only one from database
    mm.UserProfile.getEnemiesInRangeGAMEINN2 user.getThroneLevel(), user.trophies, user.gold, user.mana, excludedIds, 1, (err, users) ->
        if err
            util.log '[ERROR] Couldnt get enemies in range ' + err + ' at findNewPlayer'
        users = rand.arrayShuffle users

        for slot in user.map
            if slot.locationId == req.body.locationId
                if users[0]?
                    slot.user = users[0]._id
                    slot.occupied = true
                    slot.defeated = false
        
        user.save (err, obj) ->
            if err?
                util.log '[ERROR] When saving user ' + err + ' on map user save at findNewPlayer'

            mm.UserProfile.findById(obj._id).populate('map.user').exec (err, obj) ->
                if err?
                    util.log '[ERROR] When finding profile ' + err + ' on map user populate at findNewPlayer'

                
                userEventData = {throneLevel: req.castle.user.getThroneLevel(), trophies: req.castle.user.trophies, mana: req.castle.user.mana, gold: req.castle.user.gold}
                #foundUserEventData = {throneLevel: users[0].getThroneLevel(), trophies: users[0].trophies, mana: users[0].mana, gold: users[0].gold}

                #, foundUserData: foundUserEventData - removed
                GameInn.SendEvent 'BATTLE_SEARCH', {userID: req.castle.user._id, userData: userEventData, foundUserID: users[0]._id, reason: 'FIND_NEW_PLAYER'}, (err, data) ->
                    if err?
                        console.log err
                
                view = new mv.UserProfile(obj, {balconomy: req.app.castle.balconomy, user: user})
                res.json
                    map: view.exportMap()

exports.postReplay = (req, res, next) ->
    mm.FightHistory.findById req.body.fightHistoryId, (err, fightHistory) ->
        if err?
            util.log '[WARN] Cannot find history ' + err + ' at postReplay'
            return next err

        if fightHistory == null
            util.log '[WARN] Fight history not found'
            return next 'fight history not found'

        if req.body.replay == null
            util.log '[WARN] replay not sent'
            return next 'replay not send'

        replayBuffer = new Buffer(req.body.replay)
        mm.Replay.create({
            fightHistoryId: fightHistory._id
            replay: replayBuffer
        }, (err, replay) ->
            if err?
                util.log '[ERROR] Cannot create replay ' + err
                return next err

            fightHistory.replay = replay
            fightHistory.save (err, obj) ->
                if err?
                    util.log '[ERROR] Cannot save fightHistory ' + err + ' at postReplay'
                    return next err

                res.json
                    status: 'ok'
        )

exports.getReplay = (req, res, next) ->
    mm.Replay.findById req.query.replayId, (err, replay) ->
        if err?
            util.log '[WARN] Cannot find replay'
            return next new ex.NotImplemented

        if replay == null
            util.log '[WARN] Replay not found'
            return next new ex.NotImplemented

        #res.type('binary')
        
        rep = replay.replay.toJSON()

        res.json
            replay: rep.data
        #res.json
            #replay: replay.replay

###
@api {get} /v1/getFightHistory Request User fight history
@apiName GetFightHistoryNAME
@apiGroup User
@apiParam {Number} sample param
@apiSuccess {String} Sample success key
@apiSuccess {String} Sample success key
@apiSuccessExample Success-Response:
    HTTP/1.1 200 OK
    {
      "firstname": "John",
      "lastname": "Doe"
    }
@apiError UserNotFound The id of the User was not found.
@apiErrorExample Error-Response:
    HTTP/1.1 404 Not Found
    {
      "error": "UserNotFound"
    }
###
exports.getFightHistory = (req, res, next) ->
    ts = if req.query.timestamp then req.query.timestamp else 0
    mm.FightHistory.find({$and: [{$or: [{attacker: req.castle.user._id}, {defender: req.castle.user._id}]}, {timestamp: {$gt: ts}}]}, null, {sort:{timestamp: -1}}).populate('attacker').populate('defender').exec (err, fightList) ->
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

exports.getUserData = (req, res, next) ->
    if req.params.id == 'me' and req.castle.user.isAnonymous
        return next new ex.NotFound userId

    if req.params.id == 'random'
        user = req.castle.user

        attackCost = req.app.castle.balconomy.getAttackCost(user.getThroneLevel())

        if(attackCost != null)
            if(!user.removeResourceFromStorage(attackCost.randomAttackCost, 'GOLD'))
                util.log '[ERROR] getUserData not enough resources ' + attackCost.randomAttackCost + ' GOLD'
                return next new ex.ResetRequired("","getUserData request - not enough resources")
        
        user.save (err, user) ->
            if err?
                util.log '[ERROR] When saving user ' + err + ' at getUserData'
                return next err
    
            excludedIds = user.getMapUserIds()
            excludedIds.push user._id
            
            mm.UserProfile.getEnemiesInRangeGAMEINN2 user.getThroneLevel(), user.trophies, user.gold, user.mana, excludedIds, 50, (err, users) ->
                if(err?)
                    return next err

                if(users.length == 0)
                    return next new ex.NotFound userId

                mm.UserProfile.findOne({'_id': users[(Math.round((users.length - 1) * Math.random()))]._id}).populate('map.user').exec (err, enemy) ->

                    if not enemy?
                        if err?
                            util.log err + " in finding enemy"
                        return next new ex.NotFound userId
                    
                    mm.UserProfile.update {'_id': enemy._id}, {$set:{lastScoutTimestamp: Date.now()}}, (err, updated) ->
                        if err?
                            util.log '[ERROR] When saving enemy ' + err + ' at getUserData'
                            return next err

                        view = new mv.UserProfile(enemy, {balconomy: req.app.castle.balconomy, user: req.castle.user})
                        view.exportUserData (err, enemyView) ->
                            if err?
                                return next err

                            userEventData = {throneLevel: req.castle.user.getThroneLevel(), trophies: req.castle.user.trophies, mana: req.castle.user.mana, gold: req.castle.user.gold}
                            foundUserEventData = {throneLevel: enemy.getThroneLevel(), trophies: enemy.trophies, mana: enemy.mana, gold: enemy.gold}

                            GameInn.SendEvent 'BATTLE_SEARCH', {userID: req.castle.user._id, user:userEventData, foundUserID: enemy._id, foundUser: foundUserEventData, reason: 'QUICK_MATCH'}, (err, data) ->
                                if err?
                                    console.log err

                            res.json enemyView

    else
        userId = if req.params.id == 'me' then req.castle.user._id else req.params.id

        username = userId.toLowerCase()
        userId = if userId.length != 24 then new ObjectId "000000000000000000000000" else new ObjectId userId

        mm.UserProfile.findOne({$or:[{'_id': userId},{'username': username}]}).populate('map.user').exec (err, enemy) ->

            if not enemy?
                if err?
                    util.log err + " in finding enemy"
                return next new ex.NotFound userId

            view = new mv.UserProfile(enemy, {balconomy: req.app.castle.balconomy, user: req.castle.user})
            view.exportUserData (err, enemyView) ->
                if err?
                    return next err

                
                userEventData = {throneLevel: req.castle.user.getThroneLevel(), trophies: req.castle.user.trophies, mana: req.castle.user.mana, gold: req.castle.user.gold}
                foundUserEventData = {throneLevel: enemy.getThroneLevel(), trophies: enemy.trophies, mana: enemy.mana, gold: enemy.gold}

                GameInn.SendEvent 'BATTLE_SEARCH', {userID: req.castle.user._id, user:userEventData, foundUserID: enemy._id, foundUser: foundUserEventData, reason: 'SCOUT'}, (err, data) ->
                    if err?
                        console.log err

                res.json enemyView

#exports.getEnemyData = (req, res, next) ->
#    if req.params.id == 'me' and req.castle.user.isAnonymous
#        return next new ex.NotFound userId
#
#    userId = if req.params.id == 'me' then req.castle.user._id else req.params.id
#    util.log "[Castle API] User findById: #{userId} "
#    username = userId.toLowerCase()
#    userId = if userId.length != 24 then new ObjectId "000000000000000000000000" else new ObjectId userId
#    util.log "id n username  #{userId}} #{username}"
#
#    mm.UserProfile.findOne {$or: [{'_id': userId}, {'username': username}] }, (err, enemy) ->
#
#        if not enemy?
#            if err?
#                util.log err + " in finding enemy"
#            util.log "[Castle API] User doc not found: #{userId} "
#            return next new ex.NotFound userId
#        #  set configurable last activity timeout value
#        if Date.now() - enemy.last_user_activity <= 900000
#            return next new ex.ResourceLocked "USER_ONLINE"
#
#        enemy.isBattleOnline req.app.castle.balconomy, (err, online) ->
#            if err
#                return next err
#
#            if online
#                return next new ex.BattleOnline
#
#            view = new mv.UserProfile(enemy, req.app.castle.balconomy)
#            util.log "[Castle API] Viewing user..."
#            view.exportEnemyData (err, enemyView) ->
#                if err?
#                    return next err
#
#                res.json
#                    user: enemyView
## : change to configurable MAX TROPHIES Value
#                    trophiesToEarn: req.castle.user.getTrophiesEarn(enemy)
#                    defenderID: enemy._id

#starts battle - create FightHistory
exports.startBattle = (req, res, next) ->
    req.castle.user.isBattleOnline req.app.castle.balconomy, (err, online) ->
        if err?
            return next err

        if online
            return next new ex.BattleOnline

        userId = req.body.defenderId
        username = userId.toLowerCase()
        userId = if userId.length != 24 then new ObjectId "000000000000000000000000" else new ObjectId userId

        mm.UserProfile.findOne {$or: [{'_id': userId}, {'username': username}] }, (err, defenderUser) ->
            if err?
                return next err

            if defenderUser == null
                return next new ex.ResetRequired '', 'DEFFENDER_NOT_FOUND'

            if Date.now() - defenderUser.last_user_activity <= 900000
                return next new ex.ResourceLocked "USER_ONLINE"

            defenderUser.isBattleOnline req.app.castle.balconomy, (err, online) ->
                if err
                    return next err

                if online
                    return next new ex.BattleOnline

                sendResponse = (fightHistoryId) ->
                    view = new mv.UserProfile(defenderUser, {balconomy: req.app.castle.balconomy, user: req.castle.user})
                    view.exportEnemyData (err, enemyView) ->
                        if err?
                            return next err

                        isRevenge = false

                        if req.body.notificationId? and req.body.notificationId != ''
                            isRevenge = true

                        resources = {
                            resourcesToSteal: [
                                {
                                    resourceType: 'GOLD'
                                    quantity: mv.UserProfile.getUserResourceToStealSum(defenderUser, 'gold', req.app.castle.balconomy) * resourceStealingRatesMultiplier
                                },
                                {
                                    resourceType: 'MANA'
                                    quantity: mv.UserProfile.getUserResourceToStealSum(defenderUser, 'mana', req.app.castle.balconomy) * resourceStealingRatesMultiplier
                                }
                            ]
                        }

                        GameInn.SendEvent 'BATTLE_START', {fightHistoryID: fightHistoryId, attackerID: req.castle.user._id, defenderID: defenderUser._id, attackerThrone: req.castle.user.getThroneLevel(), defenderThrone: defenderUser.getThroneLevel(), resources: resources, revenge: isRevenge}, (err, data) ->
                            if err?
                                console.log err

                        res.json
                            enemy:
                                user: enemyView
                                trophiesToEarn: req.castle.user.getTrophiesEarn(defenderUser)
                                defenderID: defenderUser._id
                            fightHistory: fightHistoryId

                #psoltysik: resourceStealingRatesMultiplierParams
                resourceStealingRatesMultiplierParams = req.app.castle.balconomy.getResourceStealingRatesMultiplier(req.castle.user.getThroneLevel())

                resourceStealingRatesMultiplier = 1
                if(resourceStealingRatesMultiplierParams != null)
                    resourceStealingRatesMultiplier = resourceStealingRatesMultiplierParams.multiplier

                # PREVENT MULTIPLE REVENGES
                mm.FightHistory.update {attacker: req.castle.user._id, defender: defenderUser, revenge: false}, {$set:{revenge: true}}, {multi: true}, (err, history) ->
                    if err?
                        util.log '[ERROR] Cannot update fightHistory ' + err + ' at startBattle'
                        return next err

                    mm.FightHistory.create {
                        attacker: req.castle.user._id
                        defender: defenderUser
                        timestamp: Date.now()
                        ammoList: []
                        attackerTrophies: req.castle.user.trophies
                        defenderTrophies: defenderUser.trophies
                        attackerEarn: 0
                        defenderEarn: 0
                        resourcesList: []
                        destroyedRoomsList: []
                        stars: 0
                        percent: 0
                        replay: null
                        resourcesToSteal: [
                            {
                                resourceType: 'GOLD'
                                quantity: mv.UserProfile.getUserResourceToStealSum(defenderUser, 'gold', req.app.castle.balconomy) * resourceStealingRatesMultiplier
                            },
                            {
                                resourceType: 'MANA'
                                quantity: mv.UserProfile.getUserResourceToStealSum(defenderUser, 'mana', req.app.castle.balconomy) * resourceStealingRatesMultiplier
                            }
                        ]
                        revange: false
                        tutorialBattle: if defenderUser.nid == 1 then true else false
                    }, (err, fightHistory) ->
                        if err?
                            return next err
                        mm.UserProfile.update {_id: req.castle.user._id}, {$set:{activeBattle: fightHistory._id}}, (err, user) ->
                            if err?
                                util.log '[ERROR] Cannot update userProfile ' + err + ' at startBattle'
                                return next err
                            if defenderUser.profileType != 'PLAYER'
                                sendResponse fightHistory._id
                            else
                                mm.UserProfile.update {_id: defenderUser._id}, {$set:{activeBattle: fightHistory._id}}, (err, user) ->
                                    if err?
                                        util.log '[ERROR] Cannot update userProfile 2 ' + err + ' at startBattle'
                                        return next err
                                    if req.body.notificationId? and req.body.notificationId != ''
                                        mm.FightHistory.update {_id: req.body.notificationId}, {revenge: true}, (err, fight) ->
                                            if err?
                                                util.log '[ERROR] Cannot update fightHistory ' + err + ' at startBattle'
                                                return next err

                                            sendResponse fightHistory._id

                                    else
                                        sendResponse fightHistory._id

#save damage dealed in FightHistory
exports.fightDealedDamage = (req, res, next) ->
    user = req.castle.user

    req.castle.user.isBattleOnline req.app.castle.balconomy, (err, online) ->
        if err?
            util.log '[ERROR] isBattleOnline returned error ' + err + ' at fightDealedDamage'
            return next err

        if !online
            return next new ex.ResetRequired '', 'FDD BATTLE_NOT_ONLINE -> ONLINE', user.toJSON()

        mm.FightHistory.findById req.castle.user.activeBattle, (err, fightHistory) ->
            if err?
                util.log '[ERROR] Cannot find history ' + err + ' at fightDealedDamage'
                return next err

            if fightHistory == null
                return next new ex.ResetRequired '', 'FDD BATTLE_NOT_ONLINE - NO FIGHT HISTORY', user.toJSON()

            if fightHistory.isBattleEnd
                return next new ex.ResetRequired '', 'FDD BATTLE_NOT_ONLINE - BATTLE END', user.toJSON()

            if fightHistory.attacker.toString() != req.castle.user._id.toString()
                return next new ex.ResetRequired '', 'PLAYER_IS_NOT_ATTACKER'

            if fightHistory.tutorialBattle
                return res.json
                    status: 'ok'

            if req.body.damageDealed?
                fightHistory.percent = req.body.damageDealed
            else
                util.log '[WARN] Mising parameter at fightDealedDamage'
                return next new ex.ResetRequired '', 'MISSING_PARAMETER'

            if req.body.roomsDestroyed?
                fightHistory.destroyedRoomsList = req.body.roomsDestroyed

            fightHistory.save (err, fightHistory) ->
                if err?
                    util.log '[ERROR] When saving fight history ' + err + ' at fightDealedDamage'
                    return next err

                res.json
                    status: 'ok'



#save stars count in FightHistory
exports.fightStars = (req, res, next) ->
    user = req.castle.user
    req.castle.user.isBattleOnline req.app.castle.balconomy, (err, online) ->
        if err?
            util.log '[ERROR] isBattleOnline returned error ' + err + ' at fightStars'
            return next err

        if !online
            return next new ex.ResetRequired '', 'FS BATTLE_NOT_ONLINE - NOT ONLINE', user.toJSON()

        mm.FightHistory.findById req.castle.user.activeBattle, (err, fightHistory) ->
            if err?
                util.log '[ERROR] Cannot find history ' + err + ' at fightStars'
                return next err

            if fightHistory == null
                return next new ex.ResetRequired '', 'FS BATTLE_NOT_ONLINE - NO FIGHT HISTORY', user.toJSON()

            if fightHistory.isBattleEnd
                return next new ex.ResetRequired '', 'FS BATTLE_NOT_ONLINE - BATTLE END', user.toJSON()

            if fightHistory.attacker.toString() != req.castle.user._id.toString()
                return next new ex.ResetRequired '', 'PLAYER_IS_NOT_ATTACKER'

            if fightHistory.tutorialBattle
                return res.json
                    status: 'ok'

            if req.body.starsCount?
                fightHistory.stars = req.body.starsCount
                fightHistory.save (err, fightHistory) ->
                    if err?
                        util.log '[ERROR] When saving fight history ' + err + ' at fightStars'
                        return next err

                    res.json
                        status: 'ok'

            else
                util.log '[WARN] Mising parameter at fightStars'
                return next new ex.ResetRequired '', 'MISSING_PARAMETER'

exports.fightShootProjectile = (req, res, next) ->
    user = req.castle.user
    req.castle.user.isBattleOnline req.app.castle.balconomy, (err, online) ->
        if err?
            util.log '[ERROR] isBattleOnline returned error ' + err + ' at fightShootProjectile'
            return next err

        if !online
            return next new ex.ResetRequired '', 'FSP BATTLE_NOT_ONLINE - NOT ONLINE', user.toJSON()

        mm.FightHistory.findById req.castle.user.activeBattle, (err, fightHistory) ->
            if err?
                util.log '[ERROR] Cannot find history ' + err + ' at fightShootProjectile'
                return next err

            if fightHistory == null
                return next new ex.ResetRequired '', 'FSP BATTLE_NOT_ONLINE - NO FIGHT HISTORY', user.toJSON()

            if fightHistory.isBattleEnd
                return next new ex.ResetRequired '', 'FSP BATTLE_NOT_ONLINE - BATTLE END', user.toJSON()

            if fightHistory.attacker.toString() != req.castle.user._id.toString()
                return next new ex.ResetRequired '', 'PLAYER_IS_NOT_ATTACKER'

            mm.UserProfile.findById req.castle.user._id, (err, user) ->
                if err?
                    util.log '[ERROR] Cannot find user ' + err + ' at fightShootProjectile'
                    return next err

                if user == null
                    return next new ex.ResetRequired '', 'PLAYER_NOT_FOUND'

                if req.body.shootedProjectile?
                    for projectile in req.body.shootedProjectile
                        if user.removeOneProjectile projectile.projectileId, projectile.projectileLevel
                            projectileAdded = false

                            for projectileFightHistory in fightHistory.ammoList
                                if projectileFightHistory.projectileId == projectile.projectileId and projectileFightHistory.projectileLevel == projectile.projectileLevel
                                    projectileFightHistory.projectileAmount += 1
                                    projectileAdded = true
                                    break

                            if not projectileAdded
                                projectile.projectileAmount = 1
                                fightHistory.ammoList.push(projectile)

                            user.stats.projectilesUsed += 1

                        else
                            util.log '[WARN] Not enough projectile at fightShootProjectile'
                            return next new ex.ResetRequired '', 'NOT_ENOUGHT_PROJECTILE'

                    fightHistory.save (err, fightHistory) ->
                        if err?
                            util.log '[ERROR] When saving fight history ' + err + ' at fightShootProjectile'
                            return next err

                        if req.body.shootedProjectilesCombo?
                            user.setAchievementProgress 'achivDestruction', req.body.shootedProjectilesCombo

                        user.save (err, user) ->
                            if err?
                                util.log '[ERROR] When saving user ' + err + ' at fightShootProjectile'
                                return next err

                            res.json
                                status: 'ok'
                else
                    util.log '[WARN] Mising parameter at fightShootProjectile'
                    return next new ex.ResetRequired '', 'MISSING_PARAMETER'

exports.fightStealResources = (req, res, next) ->
    user = req.castle.user
    req.castle.user.isBattleOnline req.app.castle.balconomy, (err, online) ->
        if err?
            util.log '[ERROR] isBattleOnline returned error ' + err + ' at fightStealResources'
            return next err

        if !online
            return next new ex.ResetRequired '', 'FSR BATTLE_NOT_ONLINE - NOT ONLINE', user.toJSON()

        mm.FightHistory.findById req.castle.user.activeBattle, (err, fightHistory) ->
            if err?
                util.log '[ERROR] Cannot find history ' + err + ' at fightStealResources'
                return next err

            if fightHistory == null
                return next new ex.ResetRequired '', 'FSR BATTLE_NOT_ONLINE - NO FIGHT HISTORY', user.toJSON()

            if fightHistory.isBattleEnd
                return next new ex.ResetRequired '', 'FSR BATTLE_NOT_ONLINE - BATTLE END', user.toJSON()

            if fightHistory.attacker.toString() != req.castle.user._id.toString()
                return next new ex.ResetRequired '', 'PLAYER_IS_NOT_ATTACKER'

            if fightHistory.tutorialBattle
                return res.json
                    status: 'ok'

            if req.body.stolenResources?
                resoucesFound = false

                for resources in fightHistory.resourcesToSteal
                    if resources.resourceType == req.body.stolenResources.resourceType
                        resoucesFound = true
                        if resources.quantity < req.body.stolenResources.quantity
                            # util.log 'limit'
                            return next new ex.ResetRequired '', 'RESOURCES_LIMIT_REACH'

                if !resoucesFound
                    util.log '[fightStealResources] ERROR: resources limit reach'
                    return next new ex.ResetRequired '', 'RESOURCES_LIMIT_REACH'

                resourcesAdded = false

                for resources in fightHistory.resourcesList
                    if resources.resourceType == req.body.stolenResources.resourceType
                        resources.quantity = req.body.stolenResources.quantity
                        resources.quantityWithoutCollectors = req.body.stolenResources.quantityWithoutCollectors
                        resourcesAdded = true
                        break

                if !resourcesAdded
                    fightHistory.resourcesList.push req.body.stolenResources

                if req.body.productionRoomList
                    fightHistory.resourcesCollectorsList = req.body.productionRoomList

                fightHistory.save (err, fightHistory) ->
                    if err?
                        util.log '[ERROR] When saving fight history ' + err + ' at fightStealResources'
                        return next err

                    res.json
                        status: 'ok'

            else
                util.log '[WARN] Mising parameter at fightStealResources'
                return next new ex.ResetRequired '', 'MISSING_PARAMETER'

exports.endBattle = (req, res, next) ->
    user = req.castle.user
    req.castle.user.isBattleOnline req.app.castle.balconomy, (err, online) ->
        if err?
            util.log '[ERROR] isBattleOnline returned error ' + err + ' at endBattle'
            return next err

        if !online
            return next new ex.ResetRequired '', 'EB BATTLE_NOT_ONLINE - NOT ONLINE', user.toJSON()

        mm.FightHistory.findById req.castle.user.activeBattle, (err, fightHistory) ->
            if err?
                util.log '[ERROR] Cannot find history ' + err + ' at endBattle'
                return next err

            if fightHistory == null
                return next new ex.ResetRequired '', 'FightHistory is null'

            if fightHistory.isBattleEnd
                return next new ex.ResetRequired '', 'BATTLE_ENDED'

            if fightHistory.attacker.toString() != req.castle.user._id.toString()
                return next new ex.ResetRequired '', 'PLAYER_IS_NOT_ATTACKER'

            if req.body.resourcesList == undefined or req.body.stars == undefined or req.body.percent == undefined
                return next new ex.ResetRequired '', 'MISSING_PARAMETER'

            for stolenResources in req.body.resourcesList
                resoucesFound = false
                for resources in fightHistory.resourcesToSteal
                    if resources.resourceType == stolenResources.resourceType
                        resoucesFound = true
                        if resources.quantity < stolenResources.quantity
                            util.log '[ERROR] resources limit, SHOULD BE RETURNING RESET REQUIRED'
                            return next new ex.ResetRequired '', 'RESOURCES_LIMIT_REACH'

                if !resoucesFound
                    #
                    util.log '[ERROR] resources limit, SHOULD BE RETURNING RESET REQUIRED'
                    return next new ex.ResetRequired '', 'RESOURCES_LIMIT_REACH'

            for stolenResources in req.body.resourcesList
                for stolenResourcesWithoutCollectors in req.body.resourcesWithoutCollectorsList
                    if stolenResources.resourceType == stolenResourcesWithoutCollectors.resourceType
                        stolenResources.quantityWithoutCollectors = stolenResourcesWithoutCollectors.quantity

            fightHistory.resourcesList = req.body.resourcesList
            fightHistory.stars = req.body.stars
            fightHistory.percent = req.body.percent
            fightHistory.forfeit = false

            if req.body.roomsDestroyed?
                fightHistory.destroyedRoomsList = req.body.roomsDestroyed

            if req.body.productionRoomList?
                fightHistory.resourcesCollectorsList = req.body.productionRoomList

            fightHistory.endBattle req.app.castle.balconomy, (err) ->
                if err
                    util.log '[ERROR] From ending battle ' + err + ' at endBattle'
                    return next err

                res.json
                    status: 'ok'

exports.postDisplayName = (req, res, next) ->
    if req.body.display_name?
        if profanity.hasSwearWords req.body.display_name, req.headers['lang']
            return next new ex.ProfanityCheck 'SWEAR_WORD'
        else if profanity.hasSwearWords2 req.body.display_name, req.headers['lang']
            return next new ex.ProfanityCheck 'SWEAR_WORD'
        else

            req.castle.user.display_name = req.body.display_name

            req.castle.user.save (err, user) ->
                if err?
                    util.log '[ERROR] Saving display name ' + err
                    return next err

                GameInn.SendEvent 'SET_NICKNAME', {userID: user._id}, (err, data) ->
                    if err?
                        console.log err

                res.json
                    status: 'ok'
    else
        return next new ex.ProfanityCheck 'NO_DISPLAYNAME'

exports.postLootCartCollect = (req, res, next) ->
    user = req.castle.user
    COLLECTED_RESOURCES_ERROR = 0.1

    user.calculateLootCartResources(req.body.defeatedCastles, Date.now(), req.app.castle.balconomy.get())

    goldInLootCart = 0
    manaInLootCart = 0

    for resource in user.lootCart.lootCartResourcesList
        if(resource.resourceType == 'GOLD')
            goldInLootCart = resource.quantity

        else if(resource.resourceType == 'MANA')
            manaInLootCart = resource.quantity

    if(req.body.goldCollected > goldInLootCart * (1 + COLLECTED_RESOURCES_ERROR))
        errorData =
            goldCollected: req.body.goldCollected
            goldInLootCart: goldInLootCart
            calculatedGoldInLootCart: goldInLootCart * (1 + COLLECTED_RESOURCES_ERROR)
            user: user.toJSON()
        return next new ex.ResetRequired '', 'RESOURCES_LOOTCART_LIMIT_REACH_GOLD', errorData

    if(req.body.manaCollected > manaInLootCart * (1 + COLLECTED_RESOURCES_ERROR))
        errorData =
            manaCollected: req.body.manaCollected
            manaInLootCart: manaInLootCart
            calculatedManaInLootCart: manaInLootCart * (1 + COLLECTED_RESOURCES_ERROR)
            user: user.toJSON()
        return next new ex.ResetRequired '', 'RESOURCES_LOOTCART_LIMIT_REACH_MANA', errorData

    goldInLootCart = Math.max(goldInLootCart - req.body.goldCollected, 0)
    manaInLootCart = Math.max(manaInLootCart - req.body.manaCollected, 0)

    balconomy = req.app.castle.balconomy

    goldLimit = user.getGoldLimit(balconomy)
    manaLimit = user.getManaLimit(balconomy)

    for playerResource in user.castle.resourcesList
        if playerResource.resourceType == "GOLD"
            playerResource.quantity += req.body.goldCollected
            playerResource.quantity = Math.min playerResource.quantity, goldLimit
        else if playerResource.resourceType == "MANA"
            playerResource.quantity += req.body.manaCollected
            playerResource.quantity = Math.min playerResource.quantity, manaLimit

    user.setQuantityOfLootCartResources 'GOLD', goldInLootCart
    user.setQuantityOfLootCartResources 'MANA', manaInLootCart

    if(goldInLootCart == 0 && manaInLootCart == 0)
        user.lootCart.lootCartShowed = false
        user.lootCart.lastLootCartSeenTimestamp = Date.now()

    user.save (err, userProfile) ->
        if err?
            util.log '[ERROR] Saving user profile ' + err + ' at postLootCartCollect'
            return next err

        GameInn.SendEvent 'COLLECT_RESOURCES', {
            userID: req.castle.user._id, resources: [
                {type: 'GOLD', amount: req.body.goldCollected, location: 'LOOT_CART'},
                {type: 'MANA', ammount: req.body.manaCollected, location: 'LOOT_CART'}
            ]
        }, (err, data) ->
            if err?
                console.log err

        res.json
            status: 'ok'

exports.postCollectReward = (req, res, next) ->
    if req.body.locationId?
        req.castle.user.collectReward req.body.locationId, (err) ->
            if err?
                util.log '[ERROR] Collecting reward at postCollectReward ' + err
                return next ex.InternalServerError 'Cannot save reward collect'

            res.json
                status: 'ok'
    else
        return next new ex.MissingParameters ['locationId']
