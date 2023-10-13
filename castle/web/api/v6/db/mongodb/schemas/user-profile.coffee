mongoose = require 'mongoose'
bcrypt = require 'bcrypt'
u = require 'underscore'
async = require 'async'
hashids  = require 'hashids'
XRegExp = require('xregexp')
validator = require('validator')
jStat = require('jStat').jStat
crypto = require 'crypto'

randomPick = require '../../../../../util/randomPick'

mm = require('../models')
ex = require '../../../../exceptions'
util = require("util")
mongootils = require '../../../../../util/mongootils'
rand = require '../../../../../util/rand'
timeutils = require '../../../../../util/time'
versionModule = require '../../../routes/version'
version = versionModule.api.version

GameInn = require './../../../../../../../GameInn/index.js'


MATCHMAKING_TROPHIES_RANGE = 25
MATCHMAKING_THRONE_ROOM_RANGE = 1
ENEMY_USERS_LIMIT = 100
BUCKETS = 10

#in seconds
INVASION_INTERVAL = 1200
#INVASION_INTERVAL = 240
MAX_INVASION_DAYS = 14

REWARD_INTERVAL = 7200
#REWARD_INTERVAL = 240
MAX_REWARD_DAYS = 14
MAX_REWARD_CAP = 3
MIN_REWARD_VALUE = 1
MAX_REWARD_VALUE = 5
REWARD_CHANCE = 20

BASE_TROPHIES_FOR_WIN = 1

Schema = mongoose.Schema

createToken = ->
    return crypto.createHash('sha256').update('' + new Date().getTime()).digest('hex')

module.exports = UserProfile = new Schema {
    access_token: {type: String, default: createToken}
    info:
        access_created: {type: Number, default: Date.now}
        device_token: {type: String, default: ''}
        lang: {type: String, default: 'en'}
        plat: {type: String, default: 'any'}
        app: String
        last_ip : {type: String, default: ''}
        timezone: {type: Number, default: 0}
    version: {type: String, default: '2.37'}
    appVersion: {type: String, default: '2.04'}
    resetRequired: {type: Boolean, default: false}
    resetMessage: {type: String, default: ''}
    nid : {type: Number, required: true}
    username: {type: String, trim: true, lowercase: true, unique: true, sparse: true}
    email: {type: String, trim: true, lowercase: true, unique: true, sparse: true}
    password: {
        type: String
        required: true
        set: (value) ->
            @_newPassword = true

            return value
    }
    fakeAccount: {type: Boolean, default: false}
    profileType: {type: String, enum: ['NPC_BOSS', 'PLAYER', 'NPC'], default: 'PLAYER'}
    display_name: {type: String, default: ''}
    joined: {type: Number, default: Date.now}
    roles: [String]
    flags: [String]
    last_profile_data_update: {type: Number, default: 0}
    last_user_activity: {type: Number, default: Date.now}
    last_notification_visible: {type: Number, default: 0}
    trophies: {type: Number, default: 0}
    activeBattle: {type: Schema.ObjectId, ref: "FightHistory_#{version}"}
    lastScoutTimestamp: {type: Number, default: 0}
    cloud: [Number]
    currentTutorialState: {type: Number, default: 0}
    didUserRateThisApp: {type: Boolean, default: false}
    achievements: [{
        id: {type: String}
        currentProgress: {type: Number}
        lastCollectedReward: {type: Number}
    }]
    ads: {
        adsCounter: {type: Number, default: 0}
        adsFirstWatchTimestamp: {type: String, default: '01/01/0001 00:00:00'}
        freeGemsAdsCounter: {type: Number, default: 0}
        freeGemsAdsFirstWatchTimestamp: {type: String, default: '01/01/0001 00:00:00'}
    }
    timers: {
        invasion: {type: Number, default: Date.now}
        reward: {type: Number, default: Date.now}
    }
    map: [
        {
            user: {type: Schema.ObjectId, ref: "UserProfile_#{version}"}
            locationId: {type: Number}
            defeated: {type: Boolean, default: false}
            occupied: {type: Boolean, default: false}
            rubies: {type: Number, default: 0}
        }
    ]
    lootCart: {
        lootCartShowed: {type: Boolean, default: false}
        lastLootCartSeenTimestamp: {type: Number, default: 0}
        lastLootCartCollectedTimestamp: {type: Number, default: 0}
        lootCartResourcesList: [{
            quantity: {type: Number, default: 0}
            resourceType: {type: String, default: ''}
        }]
    }
    currency: {
        hard: {type: Number, default: 0}
        hardSpent: {type: Number, default: 0}
        hardBonus: {type: Number, default: 0}
    }
    castle: {
        definitionType: {type: String}
        ammoLevelsList: [{
            projectileId: {type: String, default: ''}
            projectileLevel: {type: Number, default: ''}
        }]
        ammoStoredList: [{
            projectileId: {type: String, default: ''}
            projectileLevel: {type: Number, default: 0}
            projectileAmount: {type: Number, default: 0}
            ownerId: {type: String, default: ''}
        }]
        ammoProductionList: [{
            projectileId: {type: String, default: ''}
            projectileAmount: {type: Number, default: ''}
        }]
        ammoResearch: {
            projectileId: {type: String, default: ''}
            projectileLevel: {type: Number, default: 0}
            researchStartTimestamp: {type: String, default: ''}
        }
        catapultResearchList: [{
            upgradeId: {type: String, default: ''}
            upgradeLevel: {type: Number, default: 0}
        }]
        roomsList: [{
            name: {type: String, default: ''}
            roomType: {type: String, default: ''}
            roomLevel: {type: Number, default: 0}
            buildingStartTimestamp: {type: String, default: ''}
            lastCollectTime: {type: String, default: ''}
            boostFinishTime: {type: String, default: ''}
            startTime: {type: String, default: ''}
            layoutID: {type: Number, default: 0}
            endTime: {type: String, default: ''}
            upgradeType: {type: String, default: ''}
            resourceProdQuantity: {type: Number, default: 0}
        }]
        layout: [{
            rooms: [{
                roomID: {type: Number, default: 0}
                position: {
                    x: {type: Number, default: 0}
                    y: {type: Number, default: 0}
                }
            }]
        }]
        resourcesList: [{
            quantity: {type: Number, default: 0}
            resourceType: {type: String, default: ''}
        }]
        ammoProductionStartTimestamp: {type: String, default: ''}
        activeLayout: {type: Number, default: 0}
        storyProgressList: [{
            eventId: {type: String, default: ''}
            occured: {type: Boolean, default: false}
            eventCounter: {type: Number, default: 0}
        }]
    }
    stats: {
        # Battle stats
        attacksWon: {type: Number, default: 0}
        attacksLost: {type: Number, default: 0}
        defencesWon: {type: Number, default: 0}
        defencesLost: {type: Number, default: 0}
        threeStarsWins: {type: Number, default: 0}
        projectilesUsed: {type: Number, default: 0}
        winsStreak: {type: Number, default: 0}
        bestWinsStreak: {type: Number, default: 0}
        losesStreak: {type: Number, default: 0}
        bossesDefeated: {type: Number, default: 0}
        
        # Gametime stats
        overallGameTime: {type: Number, default: 0}
        overallGamesCount: {type: Number, default: 0}

    }
},
{
    toObject: { virtuals: true }
    toJSON: { virtuals: true }
    minimize: false
}

usernameReValidator = XRegExp("^\\p{L}(?=[\\p{L}\\p{Nd}\\p{Lm}\\p{Pc}\.]{2,31}$)([\\p{L}\\p{Nd}\\p{Lm}\\p{Pc}]+\.?)*$")

UserProfile.statics.authenticate = (property, password, balconomy, onSuccess, onFailure, onError) ->
    @where(property.name?.toLowerCase(), property.value?.toLowerCase()).findOne().exec (error, doc) ->
        if error
            return onError(error)

        if doc != null
            devPassParts = password.split(':')

            if devPassParts.length == 2 and devPassParts[1] == 'hash'
            #AUTHENTICATES DEV USER IF PASSWORD IS UNKNOWN
            #JUST SET PASSWORD HASH FROM MONGO AND ADD ":hash" TO IT
                if devPassParts[0] == doc.password
                    # Start new retention history
                    util.log '(Authenticate Dev User) starting game - v5'
                    doc.startNewGame()
                    #: ATTACH FILL MAP - NOT SURE IF AT THIS PLACE
                    doc.fillMap balconomy, true, (user) ->
                        return onSuccess(user)
                else
                    return onFailure('AUTH_FAILED')
            else
                bcrypt.compare password, doc.password, (err, valid) ->

                    if valid

                        # Start new retention history
                        #util.log '[Authenticate] starting game - v5'
                        doc.startNewGame()
                        #: ATTACH FILL MAP - NOT SURE IF AT THIS PLACE
                        doc.fillMap balconomy, true, (user) ->
                            return onSuccess(user)
                    else
                        return onFailure('AUTH_FAILED')
        else
            return onFailure('USER_NOT_FOUND')


UserProfile.statics.isAvailable = (properties, cb) ->
    orParams = []

    for k, v of properties
        if v != undefined
            #FIXME Should be as easy as {"#{k}": v}
            p = {}
            p[k] = v
            orParams.push p

    if orParams.length == 0
        return cb (new Error 'At least one property has to be defined'), null

    @findOne {$or: orParams}, (err, doc) ->
        if err?
            return cb err, doc

        if not doc?
            return cb null, null

        conflicts = {}

        for k, v of properties
            if v != undefined and doc[k] == v
                conflicts[k] = v

        return cb null, conflicts

UserProfile.virtual('isAnonymous').get ->
    return false

UserProfile.virtual('isAdmin').get ->
    if @roles?
        return 'admin' in @roles

UserProfile.virtual('gold').get ->
    if @castle.resourcesList?
        for resource in @castle.resourcesList
            if resource.resourceType == "GOLD"
                return resource.quantity
    return 0

UserProfile.virtual('mana').get ->
    if @castle.resourcesList?
        for resource in @castle.resourcesList
            if resource.resourceType == "MANA"
                return resource.quantity
    return 0

UserProfile.virtual('throneLevel').get ->
    if @castle.roomsList?
        roomsList = @castle.roomsList
        for room in roomsList
            if room.roomType == 'THRONE'
                return room.roomLevel

    return 0

UserProfile.path('username').validate (value) ->

    if not value
        return false

    return usernameReValidator.test(value)

, 'Invalid username'

UserProfile.path('email').validate (value) ->

    if not value
        return false

    #if value and value.indexOf and value.indexOf("emptymail.org") != -1
    #    return true
    #else
    #    return validator.isEmail(value)
    return true
, 'Invalid email'

UserProfile.path('password').validate (value) ->
    return value and value.length > 4
, 'Too short (should be at least 5 characters long)'

UserProfile.pre 'save', true, (next, done) ->
    next()

    if @_newPassword
        bcrypt.hash @password, 10, (err, hash) =>
            @password = hash
            @_newPassword = false
            done()
    else
        done()

UserProfile.methods.resetToken = (req) ->

    if req
        last_ip = req.headers['x-forwarded-for'] || req.connection.remoteAddress
        @info.last_ip = last_ip

    @access_token = createToken()
    @info.access_created = Date.now()
        
UserProfile.methods.getMaxInvasionTryCount = () ->
    #24 hours as seconds
    return parseInt(86400 / INVASION_INTERVAL * MAX_INVASION_DAYS)

UserProfile.methods.getMaxRewardTryCount = () ->
#24 hours as seconds
    return parseInt(86400 / REWARD_INTERVAL * MAX_REWARD_DAYS)

UserProfile.methods.getMaxRewardCap = () ->
    return MAX_REWARD_CAP

UserProfile.methods.getInvasionTimes = () ->
#    util.log '-> last invasion date ' + @timers.invasion
    ts = Date.now()
#    util.log  '-> current date ' + ts

    offset = ts - @timers.invasion
    #using seconds for future safety parseInt
    offset /= 1000
#    util.log '-> offset invasion times sec' + offset
    invasionTimes = offset / INVASION_INTERVAL
    maxInvasionTimes = @getMaxInvasionTryCount()
#    util.log '-> max invasion times ' + maxInvasionTimes
#    util.log '-> invasion times 1 ' + invasionTimes
    invasionTimes = if invasionTimes > maxInvasionTimes then  maxInvasionTimes else parseInt(invasionTimes)
#    util.log '-> invasion times 2 ' + invasionTimes
    return invasionTimes

UserProfile.methods.getRewardTimes = () ->
    offset = Date.now() - @timers.reward
    #using seconds for future safety parseInt
    offset /= 1000
    rewardTimes = offset / REWARD_INTERVAL
    maxRewardTimes = @getMaxRewardTryCount()
    rewardTimes = if rewardTimes > maxRewardTimes then  maxRewardTimes else parseInt(rewardTimes)
#    util.log '-> reward times ' + rewardTimes
    return rewardTimes


returnPickedUsers = (desiredCount, user_ids, previous_user_ids, callback) ->
    
    # get random from user_ids and add them to picked
    if desiredCount > user_ids.length
        console.log '[returnPickedUsers ERROR] Impossible to get ' + desiredCount + ' ids from user_ids: ' + user_ids.length
    
    picked_random_user_ids = rand.pickRandomGammaUsers user_ids, Math.min(desiredCount, user_ids.length) # get random people
    
    # console.log '[returnPickedUsers] user_ids: ' + user_ids.length + ', previous_user_ids: ' + previous_user_ids.length + ', picked_random_user_ids: ' + picked_random_user_ids.length
    
    picked_user_ids = previous_user_ids.concat(picked_random_user_ids)  # add previously picked users
    data = ' '
    # console.log '[returnPickedUsers] picked_user_ids: ' + picked_user_ids.length + ', previous_user_ids: ' + previous_user_ids.length + ', picked_random_user_ids: ' + picked_random_user_ids.length
    for picked_user_id in picked_user_ids
        data += JSON.stringify(picked_user_id) + ' '

    # console.log 'picked : ' + data
    
    mm.UserProfile.find({'_id': {$in: picked_user_ids}}).exec (err, users) ->
        if err?
            console.log '[returnPickedUsers] Error finding users in Mongo!'
            return new ex.InternalServerError 'Bad Mongo'

        #console.log '[returnPickedUsers] returned: ' + users.length + ' users'
        return callback null, users


returnPickedUsers2 = (desiredCount, user_ids_array, previous_users_ids_array, callback) ->
    
    if (previous_users_ids_array == null)   # failsafe for null
        previous_users_ids_array = []

    # get random from user_ids and add them to picked
    #if desiredCount > user_ids_array.length
        # console.log '[returnPickedUsers ERROR] Impossible to get ' + desiredCount + ' ids from user_ids: ' + user_ids_array.length
    
    picked_random_user_ids = randomPick.randomBetaPick user_ids_array, desiredCount  # get randomly people

    mm.UserProfile.find({ $or: [{'_id': {$in: picked_random_user_ids}}, {'_id': {$in: previous_users_ids_array}}] }).exec (err, users) ->
        if err?
            console.log '[UserProfile returnPickedUsers2 ERROR] Error finding users in Mongo!'
            return callback new ex.InternalServerError 'Bad Mongo', null
        
        return callback null, users


UserProfile.statics.getEnemiesInRange2 = (userThroneLevel, userTrophies, idsExcluded, desiredCount, callback) ->
#: powinien byc podany parametr ilu enemies chcemy zwrócić
# timeQuery - prepared for people that have been idle longer than 5 minutes
# paramQuery - someday we will remove friends, clan members here
    
    timestamp = Date.now() - 900000 # 15 minutes later
    limit_timestamp = Date.now() - 1209600000 #  two weeks later
    
    sortBy = '-joined'
    usernamesExcluded = ['castle_admin', 'lord_greyson', 'lord_jeffrey']
    idsExcluded = mongootils.ConvertToIdsArray idsExcluded
    paramQuery = {'username': {$nin: usernamesExcluded}, currentTutorialState: 1, profileType: 'PLAYER', '_id': {$nin: idsExcluded}}
    timeQuery = {'last_user_activity': {$lt: timestamp, $gt: limit_timestamp}}
    trophiesQuery = {'trophies':{$lt: userTrophies + MATCHMAKING_TROPHIES_RANGE, $gt: userTrophies - MATCHMAKING_TROPHIES_RANGE}}
    throneRoomQuery = {'castle.roomsList':{$elemMatch:{"roomType":"THRONE", "roomLevel":{$gte: userThroneLevel - MATCHMAKING_THRONE_ROOM_RANGE, $lte: userThroneLevel + MATCHMAKING_THRONE_ROOM_RANGE}}}}
    query =
        '$and': [paramQuery, timeQuery, trophiesQuery, throneRoomQuery]

    #  Add skip with random jump and sort with unusual IN WATERFALL ASYNC
    mm.UserProfile.find(query).count (err, fittotal) ->
        if err?
            return callback err, null
        # GET SOME USERS IN RANGE, NOT ONLY THE BEGINNING ONES
        
        total = Math.max(fittotal, desiredCount + 1)
        skipEnemies = rand.randomRange(0, total - desiredCount + 1)

        mm.UserProfile.find(query).skip(skipEnemies).limit(desiredCount).exec (err, users) ->
            if err?
                return callback err, null
            # util.log '[getEnemiesInRange] got fitting: ' + users.length
            #: powinno byc sprawdzone czy ilosc ktora potrzebujemy zgadza sie z iloscia wyciagnieta z mongo (a nie samo length)
            if users.length == desiredCount
                callback null, users
            else
                # we dont have enough users

                desiredCount -= users.length
                query =
                    '$and': [paramQuery, timeQuery, throneRoomQuery]
                mm.UserProfile.find(query).count (err, thronetotal) ->
                    if err?
                        return callback err, null
                    total = Math.max(thronetotal, desiredCount + 1)
                    skipEnemies = rand.randomRange(0, total - desiredCount + 1)

                    mm.UserProfile.find(query).skip(skipEnemies).limit(desiredCount).exec (err, throneusers) ->
                        if err?
                            return callback err, null
                        
                        users = users.concat(throneusers)

                        if throneusers.length == desiredCount
                            return callback null, users
                        
                        # we still dont have enough users
                        
                        desiredCount -= throneusers.length
    
                        query =
                            '$and': [paramQuery, timeQuery, trophiesQuery]
                        
                        mm.UserProfile.find(query).count (err, trophiestotal) ->
                            if err?
                                return callback err, null
                            total = Math.max(trophiestotal, desiredCount + 1)
                            skipEnemies = rand.randomRange(0, total - desiredCount + 1)

                            mm.UserProfile.find(query).skip(skipEnemies).limit(desiredCount).exec (err, trophiesusers) ->
                                if err?
                                    return callback err, null
                                
                                users = users.concat(trophiesusers)

                                if trophiesusers.length == desiredCount
                                    return callback null, users
                                
                                # we still dont have enough users
                                
                                desiredCount -= trophiesusers.length

                                mm.UserProfile.find(paramQuery).count (err, alltotal) ->
                                    if err?
                                        return callback err, null
                                    restUsers = desiredCount
                                    alltotal = Math.max(alltotal, restUsers + 1)
                                    skipEnemies = rand.randomRange(0, alltotal - restUsers + 1)
                                    mm.UserProfile.find(paramQuery).skip(skipEnemies).limit(restUsers).exec (err, allusers) ->
                                        util.log '[WARN] found not enough desired enemies in range: ' + users.length + ', rest of desired:' + desiredCount + ' at getEnemiesInRange'
                                        util.log '[WARN] returning rest of ordinary users: ' + allusers.length + ' at getEnemiesInRange'
                                        
                                        return callback null, users.concat(allusers)

UserProfile.statics.getEnemiesInRangeGAMEINN = (userThroneLevel, userTrophies, userGold, userMana, idsExcluded, desiredCount, callback) ->
#: powinien byc podany parametr ilu enemies chcemy zwrócić
# timeQuery - prepared for people that have been idle longer than 5 minutes
# paramQuery - someday we will remove friends, clan members here
    
    sample_size = desiredCount * 10 # SAMPLE USERS by one magnitude
    start_timestamp = Date.now() - 900000 # 15 minutes later - start of active users (but not active right now)
    end_timestamp = Date.now() - 1209600000 #  two weeks later - end of active users

    #usernamesExcluded = ['castle_admin', 'lord_greyson', 'lord_jeffrey'] (OLD ParamQuery: 'username': {$nin: usernamesExcluded}, ...)
    idsExcluded = mongootils.ConvertToIdsArray idsExcluded
    
    paramQuery = {'currentTutorialState': 1, 'profileType': 'PLAYER', '_id': {$nin: idsExcluded}}
    timeQuery = {'last_user_activity': {$lt: start_timestamp, $gt: end_timestamp}}
    trophiesQuery = {'trophies':{$lt: userTrophies + MATCHMAKING_TROPHIES_RANGE, $gt: userTrophies - MATCHMAKING_TROPHIES_RANGE}}
    throneRoomQuery = {'castle.roomsList':{$elemMatch:{"roomType":"THRONE", "roomLevel":{$gte: userThroneLevel, $lte: userThroneLevel + 1}}}}
    resourceGoldQuery = {'castle.resourcesList':{$elemMatch:{"resourceType":"GOLD", "quantity":{$gte:userGold}}}}
    resourceManaQuery = {'castle.resourcesList':{$elemMatch:{"resourceType":"MANA", "quantity":{$gte:userMana}}}}
    
    idsChosen = []
    chosenQuery = {'_id': {$nin: idsChosen}}
    
    # console.log "[getEnemiesInRange INFO] desired users: " + desiredCount
    # aggregate sample from our users that fit the conditions and sort for last_activity
    # get their ids

    mm.UserProfile.aggregate( [
        {"$match": {$and: [paramQuery, timeQuery, trophiesQuery, throneRoomQuery, resourceGoldQuery, resourceManaQuery]}},
        { $sort: {"last_user_activity":-1}},
        { $sample : {size: sample_size}},
        {"$project" :{"_id": 1}}
    ]).exec (err, user_ids) ->
        if err?
            console.log "[UserProfile ERROR] getEnemiesInRange - Error with aggregate from Mongo"
            return callback err, null
        
        # console.log "[getEnemiesInRange INFO] best-fitting users: " + user_ids.length
        
        user_ids_array = mongootils.ConvertIdsToArray user_ids
        
        if (user_ids.length >= desiredCount)
            return returnPickedUsers2(desiredCount, user_ids_array, null, callback)

        else # (user_ids.length < desiredCount)  # too small number, we need to warn
            
            desiredCount -= user_ids.length  # new desiredCount
            ids_already_picked_array = user_ids_array
            previousQuery = {'_id': {$nin: ids_already_picked_array }}
            sample_size = desiredCount * 10

            # pick without trophies requirement
            mm.UserProfile.aggregate( [
                {"$match": {$and: [paramQuery, timeQuery, throneRoomQuery, resourceGoldQuery, resourceManaQuery, previousQuery]}},
                { $sort: {"last_user_activity":-1}},
                { $sample : {size: sample_size}},
                {"$project" :{"_id": 1}}
            ]).exec (err, th_user_ids) ->
                if err?
                    console.log "[UserProfile ERROR] getEnemiesInRange throne repick - Error with aggregate from Mongo"
                    return callback err, null
                
                # console.log "[getEnemiesInRange INFO] throne-fitting users: " + th_user_ids.length
        
                th_user_ids_array = mongootils.ConvertIdsToArray th_user_ids

                if (th_user_ids.length >= desiredCount)
                    return returnPickedUsers2(desiredCount, th_user_ids_array, ids_already_picked_array, callback)
                
                else # (th_user_ids.length < desiredCount)  # too small number, we need to warn

                    ids_already_picked_array = ids_already_picked_array.concat(th_user_ids_array)
                    desiredCount -= th_user_ids.length
                    previousQuery = {'_id': {$nin: ids_already_picked_array }}
                    sample_size = desiredCount * 10
                    
                    # pick without throne requirement
                    mm.UserProfile.aggregate( [
                        {"$match": {$and: [paramQuery, throneRoomQuery, resourceGoldQuery, resourceManaQuery, previousQuery]}},
                        { $sort: {"last_user_activity":-1}},
                        { $sample : {size: sample_size}},
                        {"$project" :{"_id": 1}}
                    ]).exec (err, tr_user_ids) ->
                        if err?
                            console.log "[UserProfile ERROR] getEnemiesInRange  trophies pick - Error with aggregate from Mongo"
                            return callback err, null

                        # console.log "[getEnemiesInRange INFO] trophies-fitting users: " + tr_user_ids.length
        
                        tr_user_ids_array = mongootils.ConvertIdsToArray tr_user_ids

                        if (tr_user_ids.length >= desiredCount)
                            return returnPickedUsers2(desiredCount, tr_user_ids_array, ids_already_picked_array, callback)

                        else

                            ids_already_picked_array = ids_already_picked_array.concat(tr_user_ids_array)
                            desiredCount -= tr_user_ids.length
                            previousQuery = {'_id': {$nin: ids_already_picked_array }}
                            sample_size = desiredCount * 10
                            
                            # pick with only time requirement
                            mm.UserProfile.aggregate( [
                                {"$match": {$and: [paramQuery, throneRoomQuery, previousQuery]}},
                                { $sort: {"last_user_activity":-1}},
                                { $sample : {size: sample_size}},
                                {"$project" :{"_id": 1}}
                            ]).exec (err, time_user_ids) ->
                                if err?
                                    console.log "[UserProfile ERROR] getEnemiesInRange time pick - Error with aggregate from Mongo"
                                    return callback err, null
                                
                                # console.log "[getEnemiesInRange INFO] time-fitting users: " + time_user_ids.length
        
                                time_user_ids_array = mongootils.ConvertIdsToArray time_user_ids

                                if (time_user_ids.length >= desiredCount)
                                    return returnPickedUsers2(desiredCount, time_user_ids_array, ids_already_picked_array, callback)

                                else

                                    ids_already_picked_array = ids_already_picked_array.concat(time_user_ids_array)
                                    desiredCount -= time_user_ids.length
                                    previousQuery = {'_id': {$nin: ids_already_picked_array }}
                                    sample_size = desiredCount * 10

                                    # pick with no time requirements
                                    mm.UserProfile.aggregate( [
                                        {"$match": {$and: [paramQuery, previousQuery]}},
                                        { $sort: {"last_user_activity":-1}},
                                        { $sample : {size: sample_size}},
                                        {"$project" :{"_id": 1}}
                                    ]).exec (err, all_user_ids) ->
                                        if err?
                                            console.log "[UserProfile ERROR] getEnemiesInRange all-over pick - Error with aggregate from Mongo"
                                            return callback err, null
                                      
                                        # console.log "[getEnemiesInRange INFO] other users: " + all_user_ids.length
                                        all_user_ids_array = mongootils.ConvertIdsToArray all_user_ids
                                        
                                        if (all_user_ids.length >= desiredCount)
                                            return returnPickedUsers2(desiredCount, all_user_ids_array, ids_already_picked_array, callback)

                                        else
                                            console.log "[UserProfile ERROR] getEnemiesInRange all-over pick - Not sufficient users count!"
                                            return callback new ex.InternalServerError '[Error with getting any users for getEnemies] ', null

                                            
UserProfile.statics.getEnemiesInRangeGAMEINN2 = (userThroneLevel, userTrophies, userGold, userMana, idsExcluded, desiredCount, callback) ->
    `
    var o = {};
    o.map = function () { 
        if(this.last_user_activity < maxTimestamp && this.last_user_activity > minTimestamp) {
            var gold = 0;
            var mana = 0;
            var throneLevel = 0;

            for(var resourceIndex in this.castle.resourcesList) {
                var resource = this.castle.resourcesList[resourceIndex];
                if(resource.resourceType == "GOLD") {
                    gold = resource.quantity * 0.5;
                } else if(resource.resourceType == "MANA") {
                    mana = resource.quantity * 0.5;
                }
            }

            var clientTimeformatToTimestamp = function(datestring) {
                var dateChunks = datestring.split(/\/| |:/);
                var day = dateChunks[0];
                var month = dateChunks[1] - 1;
                var year = dateChunks[2];
                var hour = dateChunks[3];
                var minutes = dateChunks[4];
                var seconds = dateChunks[5];
                var date = new Date(year, month, day, hour, minutes, seconds, 0);

                return date.getTime();
            }

            var calculateResourcesInRoom = function(room, roomParams, productionBoost) {
                var normalSpan = 0
                var boostedSpan = 0
                var date = Date.now();

                var boostFinishTime = clientTimeformatToTimestamp(room.boostFinishTime) / 1000;
                var lastCollectTime = clientTimeformatToTimestamp(room.lastCollectTime) / 1000;

                if(lastCollectTime < date)
                    if(lastCollectTime >= boostFinishTime)
                        normalSpan = date - lastCollectTime;
                    else if(date <= boostFinishTime)
                        boostedSpan = date - lastCollectTime;
                    else if(lastCollectTime < boostFinishTime && date > boostFinishTime)
                        boostedSpan = boostFinishTime - lastCollectTime;
                        normalSpan = date - boostFinishTime;

                normalProductionSum = normalSpan * roomParams.productionRate;
                boostedProductionSum = boostedSpan * roomParams.productionRate * productionBoost;
                resourcesSum = room.resourceProdQuantity + Math.floor(normalProductionSum + boostedProductionSum);
                resourcesSum = Math.min(resourcesSum, roomParams.capacity);
                return Math.ceil(resourcesSum * 0.5);
            }
            
            for(var roomIndex in this.castle.roomsList) {
                var room = this.castle.roomsList[roomIndex];
                if(room.roomType == "TAX_COLLECTOR")
                {
                    for(var paramsIndex in taxCollectorsParams.roomLevels)
                    {
                        if(taxCollectorsParams.roomLevels[paramsIndex].level == room.roomLevel)
                        {
                            gold += calculateResourcesInRoom(room, taxCollectorsParams.roomLevels[paramsIndex], productionBoost);
                            break;
                        }
                    }
                }
                else if(room.roomType == "ALCHEMICAL_WORKSHOP")
                {
                    for(var paramsIndex in manaCollectorsParams.roomLevels)
                    {
                        if(manaCollectorsParams.roomLevels[paramsIndex].level == room.roomLevel)
                        {
                            mana += calculateResourcesInRoom(room, manaCollectorsParams.roomLevels[paramsIndex], productionBoost);
                            break;
                        }
                    }
                }
                else if(room.roomType == "THRONE")
                {
                    throneLevel == room.roomLevel;
                }
            }

            emit(this._id, {trophies: this.trophies, mana: mana, gold: gold, throneLevel: throneLevel});
        }
    };
    o.reduce = function (k, vals) { 
        return vals[0];
    };
    o.verbose = true;
    o.scope = {
        maxTimestamp: Date.now() - 900000,
        minTimestamp: Date.now() - 1209600000,
        taxCollectorsParams: {
            roomLevels:[  
                {
                    productionRate:0,
                    capacity:0,
                    level:0
                },
                {
                    productionRate:0.05555000156164169,
                    capacity:500,
                    level:1
                },
                {
                    productionRate:0.11110000312328339,
                    capacity:1200,
                    level:2
                },
                {
                    productionRate:0.16665999591350555,
                    capacity:2500,
                    level:3
                },
                {
                    productionRate:0.22222000360488892,
                    capacity:5000,
                    level:4
                },
                {
                    productionRate:0.2777700126171112,
                    capacity:8000,
                    level:5
                },
                {
                    productionRate:0.36111000180244446,
                    capacity:12000,
                    level:6
                },
                {
                    productionRate:0.44444000720977783,
                    capacity:15000,
                    level:7
                },
                {
                    productionRate:0.5,
                    capacity:20000,
                    level:8
                },
                {
                    productionRate:0.5277777910232544,
                    capacity:30000,
                    level:9
                },
                {
                    productionRate:0.5555555820465088,
                    capacity:50000,
                    level:10
                }
            ],
        },
        manaCollectorsParams: {
            roomLevels:[  
                {
                    productionRate:0,
                    capacity:0,
                    level:0
                },
                {
                    productionRate:0.05555000156164169,
                    capacity:500,
                    level:1
                },
                {
                    productionRate:0.11110000312328339,
                    capacity:1200,
                    level:2
                },
                {
                    productionRate:0.16665999591350555,
                    capacity:2500,
                    level:3
                },
                {
                    productionRate:0.22222000360488892,
                    capacity:5000,
                    level:4
                },
                {
                    productionRate:0.2777700126171112,
                    capacity:8000,
                    level:5
                },
                {
                    productionRate:0.36111000180244446,
                    capacity:12000,
                    level:6
                },
                {
                    productionRate:0.44444000720977783,
                    capacity:15000,
                    level:7
                },
                {
                    productionRate:0.5,
                    capacity:20000,
                    level:8
                },
                {
                    productionRate:0.5277777910232544,
                    capacity:30000,
                    level:9
                },
                {
                    productionRate:0.5555555820465088,
                    capacity:50000,
                    level:10
                }
            ],
        },
        productionBoost: 2,
    }

    var mapReduceCallback = function (err, results, stats) {
        if(err != null) {
            console.log(err);
        } else {
            var firstStageMatchmaking = [];
            var secondStageMatchmaking = [];
            var thirdStageMatchmaking = [];

            for(var profileIndex in results) {
                var profile = results[profileIndex];
                var profileResources = profile.gold + profile.mana;
                var userResources = userGold + userMana;
                if(profile.throneLevel >= userThroneLevel && profile.throneLevel <= userThroneLevel + 1) {
                    if(profileResources >= userResources * 2) {
                        if(profile.trophies >= userTrophies - MATCHMAKING_TROPHIES_RANGE &&profile.trophies >= userTrophies - MATCHMAKING_TROPHIES_RANGE) {
                            firstStageMatchmaking.push(profile);
                            continue;
                        } else {
                            secondStageMatchmaking.push(profile);
                            continue;
                        }
                    } else {
                    thirdStageMatchmaking.push(profile);
                    continue;
                    }
                } else {
                    thirdStageMatchmaking.push(profile);
                    continue;
                }
            }

            firstStageMatchmaking = rand.arrayShuffle(firstStageMatchmaking);
            secondStageMatchmaking = rand.arrayShuffle(secondStageMatchmaking);
            thirdStageMatchmaking = rand.arrayShuffle(thirdStageMatchmaking);

            var result = [];

            if(firstStageMatchmaking.length >= desiredCount) {
                for(; desiredCount > 0; desiredCount--) {
                    var index = Math.floor((Math.random() * firstStageMatchmaking.length));
                    result.push(firstStageMatchmaking[index]);
                    firstStageMatchmaking.splice(index, 1);
                }
                return callback(null, result);
            }

            result = result.concat(firstStageMatchmaking);
            desiredCount -= firstStageMatchmaking.length;

            if(secondStageMatchmaking.length >= desiredCount) {
                for(; desiredCount > 0; desiredCount--) {
                    var index = Math.floor((Math.random() * secondStageMatchmaking.length));
                    result.push(secondStageMatchmaking[index]);
                    secondStageMatchmaking.splice(index, 1);
                }
                return callback(null, result);
            }

            result = result.concat(secondStageMatchmaking);
            desiredCount -= secondStageMatchmaking.length;

            if(thirdStageMatchmaking.length >= desiredCount) {
                for(; desiredCount > 0; desiredCount--) {
                    var index = Math.floor((Math.random() * thirdStageMatchmaking.length));
                    result.push(thirdStageMatchmaking[index]);
                    thirdStageMatchmaking.splice(index, 1);
                }
                return callback(null, result);
            }

            result = result.concat(thirdStageMatchmaking);
            desiredCount -= thirdStageMatchmaking.length;

            returnPickedUsers2(desiredCount, result, result, callback)
        }
    };
    `

    mm.UserProfile.mapReduce(o, mapReduceCallback)


UserProfile.statics.getEnemiesInRange = (userThroneLevel, userTrophies, idsExcluded, desiredCount, callback) ->
#: powinien byc podany parametr ilu enemies chcemy zwrócić
# timeQuery - prepared for people that have been idle longer than 5 minutes
# paramQuery - someday we will remove friends, clan members here
    
    sample_size = desiredCount * 10 # SAMPLE USERS by one magnitude
    start_timestamp = Date.now() - 900000 # 15 minutes later - start of active users (but not active right now)
    end_timestamp = Date.now() - 1209600000 #  two weeks later - end of active users

    #usernamesExcluded = ['castle_admin', 'lord_greyson', 'lord_jeffrey'] (OLD ParamQuery: 'username': {$nin: usernamesExcluded}, ...)
    idsExcluded = mongootils.ConvertToIdsArray idsExcluded
    
    paramQuery = {'currentTutorialState': 1, 'profileType': 'PLAYER', '_id': {$nin: idsExcluded}}
    timeQuery = {'last_user_activity': {$lt: start_timestamp, $gt: end_timestamp}}
    trophiesQuery = {'trophies':{$lt: userTrophies + MATCHMAKING_TROPHIES_RANGE, $gt: userTrophies - MATCHMAKING_TROPHIES_RANGE}}
    throneRoomQuery = {'castle.roomsList':{$elemMatch:{"roomType":"THRONE", "roomLevel":{$gte: userThroneLevel - MATCHMAKING_THRONE_ROOM_RANGE, $lte: userThroneLevel + MATCHMAKING_THRONE_ROOM_RANGE}}}}
    
    idsChosen = []
    chosenQuery = {'_id': {$nin: idsChosen}}
    
    # console.log "[getEnemiesInRange INFO] desired users: " + desiredCount
    # aggregate sample from our users that fit the conditions and sort for last_activity
    # get their ids

    mm.UserProfile.aggregate( [
        {"$match": {$and: [paramQuery, timeQuery, trophiesQuery, throneRoomQuery]}},
        { $sort: {"last_user_activity":-1}},
        { $sample : {size: sample_size}},
        {"$project" :{"_id": 1}}
    ]).exec (err, user_ids) ->
        if err?
            console.log "[UserProfile ERROR] getEnemiesInRange - Error with aggregate from Mongo"
            return callback err, null
        
        # console.log "[getEnemiesInRange INFO] best-fitting users: " + user_ids.length
        
        user_ids_array = mongootils.ConvertIdsToArray user_ids
        
        if (user_ids.length >= desiredCount)
            return returnPickedUsers2(desiredCount, user_ids_array, null, callback)

        else # (user_ids.length < desiredCount)  # too small number, we need to warn
            
            desiredCount -= user_ids.length  # new desiredCount
            ids_already_picked_array = user_ids_array
            previousQuery = {'_id': {$nin: ids_already_picked_array }}
            sample_size = desiredCount * 10

            # pick without trophies requirement
            mm.UserProfile.aggregate( [
                {"$match": {$and: [paramQuery, timeQuery, throneRoomQuery, previousQuery]}},
                { $sort: {"last_user_activity":-1}},
                { $sample : {size: sample_size}},
                {"$project" :{"_id": 1}}
            ]).exec (err, th_user_ids) ->
                if err?
                    console.log "[UserProfile ERROR] getEnemiesInRange throne repick - Error with aggregate from Mongo"
                    return callback err, null
                
                # console.log "[getEnemiesInRange INFO] throne-fitting users: " + th_user_ids.length
        
                th_user_ids_array = mongootils.ConvertIdsToArray th_user_ids

                if (th_user_ids.length >= desiredCount)
                    return returnPickedUsers2(desiredCount, th_user_ids_array, ids_already_picked_array, callback)
                
                else # (th_user_ids.length < desiredCount)  # too small number, we need to warn

                    ids_already_picked_array = ids_already_picked_array.concat(th_user_ids_array)
                    desiredCount -= th_user_ids.length
                    previousQuery = {'_id': {$nin: ids_already_picked_array }}
                    sample_size = desiredCount * 10
                    
                    # pick without throne requirement
                    mm.UserProfile.aggregate( [
                        {"$match": {$and: [paramQuery, timeQuery, trophiesQuery, previousQuery]}},
                        { $sort: {"last_user_activity":-1}},
                        { $sample : {size: sample_size}},
                        {"$project" :{"_id": 1}}
                    ]).exec (err, tr_user_ids) ->
                        if err?
                            console.log "[UserProfile ERROR] getEnemiesInRange  trophies pick - Error with aggregate from Mongo"
                            return callback err, null

                        # console.log "[getEnemiesInRange INFO] trophies-fitting users: " + tr_user_ids.length
        
                        tr_user_ids_array = mongootils.ConvertIdsToArray tr_user_ids

                        if (tr_user_ids.length >= desiredCount)
                            return returnPickedUsers2(desiredCount, tr_user_ids_array, ids_already_picked_array, callback)

                        else

                            ids_already_picked_array = ids_already_picked_array.concat(tr_user_ids_array)
                            desiredCount -= tr_user_ids.length
                            previousQuery = {'_id': {$nin: ids_already_picked_array }}
                            sample_size = desiredCount * 10
                            
                            # pick with only time requirement
                            mm.UserProfile.aggregate( [
                                {"$match": {$and: [paramQuery, timeQuery, previousQuery]}},
                                { $sort: {"last_user_activity":-1}},
                                { $sample : {size: sample_size}},
                                {"$project" :{"_id": 1}}
                            ]).exec (err, time_user_ids) ->
                                if err?
                                    console.log "[UserProfile ERROR] getEnemiesInRange time pick - Error with aggregate from Mongo"
                                    return callback err, null
                                
                                # console.log "[getEnemiesInRange INFO] time-fitting users: " + time_user_ids.length
        
                                time_user_ids_array = mongootils.ConvertIdsToArray time_user_ids

                                if (time_user_ids.length >= desiredCount)
                                    return returnPickedUsers2(desiredCount, time_user_ids_array, ids_already_picked_array, callback)

                                else

                                    ids_already_picked_array = ids_already_picked_array.concat(time_user_ids_array)
                                    desiredCount -= time_user_ids.length
                                    previousQuery = {'_id': {$nin: ids_already_picked_array }}
                                    sample_size = desiredCount * 10

                                    # pick with no time requirements
                                    mm.UserProfile.aggregate( [
                                        {"$match": {$and: [paramQuery, previousQuery]}},
                                        { $sort: {"last_user_activity":-1}},
                                        { $sample : {size: sample_size}},
                                        {"$project" :{"_id": 1}}
                                    ]).exec (err, all_user_ids) ->
                                        if err?
                                            console.log "[UserProfile ERROR] getEnemiesInRange all-over pick - Error with aggregate from Mongo"
                                            return callback err, null
                                      
                                        # console.log "[getEnemiesInRange INFO] other users: " + all_user_ids.length
                                        all_user_ids_array = mongootils.ConvertIdsToArray all_user_ids
                                        
                                        if (all_user_ids.length >= desiredCount)
                                            return returnPickedUsers2(desiredCount, all_user_ids_array, ids_already_picked_array, callback)

                                        else
                                            console.log "[UserProfile ERROR] getEnemiesInRange all-over pick - Not sufficient users count!"
                                            return callback new ex.InternalServerError '[Error with getting any users for getEnemies] ', null

##################################

UserProfile.statics.getNPC = (cb) ->
    mm.UserProfile.find({profileType: {$ne: 'PLAYER'}}).sort({nid: 1}).exec (err, boss) ->
        bosses = {}
        if err?
            util.log '[ERROR] ' + err + ' error in getNPC'
            cb bosses
        else
            for b in boss
                key = b.nid.toString()
                bosses[key] = b
                #                util.log 'found boss ' + key

            cb(bosses)


UserProfile.methods.getTrophiesEarn = (enemyProfile) ->

    return BASE_TROPHIES_FOR_WIN
    #we pass all enemy profile because in future probably we use more data than trophies
    #trophies = Math.atan(0.05*(enemyProfile.trophies - @trophies)) / Math.PI
    #trophies = 50 + (2 * trophies * 50)

    #return parseInt(trophies)

UserProfile.methods.getResourcesToSteal = () ->
    resourcesToStealArray = []

    for resource in @castle.resourcesList
        resourceToSteal = {}
        resourceToSteal.quantity = resource.quantity * 0.3
        resourceToSteal.resourceType = resource.resourceType
        resourcesToStealArray.push(resourceToSteal)

    return resourcesToStealArray

UserProfile.methods.getExplorerLevel = () ->
    return @getRoomLevel 'EXPLORER'

UserProfile.methods.getThroneLevel = () ->
    return @getRoomLevel 'THRONE'

UserProfile.methods.getRoomLevel = (roomType) ->
    roomsList = @castle.roomsList
    for room in roomsList
        if room.roomType == roomType
            return room.roomLevel

    return 0

UserProfile.methods.getRoom = (roomName) ->
    roomsList = @castle.roomsList
    for room in roomsList
        if room.name == roomName
            return room

    return null

UserProfile.methods.getMapUserIds = () ->
    userIds = []
    for m in @map
        if m.user != null
            userIds.push(m.user.toString())

    return userIds

UserProfile.methods.getMapEnemyCount = () ->
    enemyCount = 0
    for m in @map
        if not m.defeated and m.occupied
            enemyCount++

    return enemyCount

UserProfile.methods.getMapRewardCount = () ->
    rewardCount = 0
    for m in @map
        if m.rubies > 0
            rewardCount++

    return rewardCount


UserProfile.methods.getMapInvasionLocations = (maxInvasionIds) ->
    locationIds = []
    for m in @map
        if m.defeated or not m.occupied
            #push version which adds element on the beginning of the array
            locationIds.unshift(m.locationId)

    return rand.arrayShuffle locationIds.slice(0, maxInvasionIds)

UserProfile.methods.getMapRewardLocations = (maxRewardIds) ->
    locationIds = []
    for m in @map
        if (m.defeated or not m.occupied) and m.rubies == 0
            locationIds.push(m.locationId)

    return rand.arrayShuffle locationIds.slice(0, maxRewardIds)

UserProfile.methods.removeOneProjectile = (projectileId, projectileLevel) ->
    projectileRemoved = false
    projectileType = null

    for projectile in @castle.ammoStoredList
        if projectile.projectileId == projectileId and projectile.projectileLevel == projectileLevel
            projectile.projectileAmount--
            projectileRemoved = true
            projectileType = projectile
            break
    
    # FOR CODE REVIEW - projectile is declared in loop above
    @castle.ammoStoredList = @castle.ammoStoredList.filter (projectileType) ->
        return projectileType.projectileAmount != 0

    return projectileRemoved

UserProfile.methods.fillMap = (balconomy, isInit, cb) ->
    explorerLevel = @getExplorerLevel()
    mapSlotsCount = balconomy.getRadarSlotRange explorerLevel
    mapUserIds = @getMapUserIds()
    user = @

    #fill map for new territory
    if mapSlotsCount > user.map.length
        user.generateNewMapSlots balconomy, mapSlotsCount, mapUserIds, explorerLevel, cb
    else
        user.refillMapSlots balconomy, mapSlotsCount, mapUserIds, explorerLevel, isInit, cb

UserProfile.methods.generateNewMapSlots = (balconomy, mapSlotsCount, mapUserIds, explorerLevel, cb) ->
    user = @
    prevMapSlotsCount = user.map.length
    newSlotsCount = mapSlotsCount - prevMapSlotsCount
#    util.log 'prevMapSlotsCount ' + prevMapSlotsCount
    excludedQueryIds = mapUserIds
    excludedQueryIds.push user._id

    mm.UserProfile.getNPC (npc) ->
        mm.UserProfile.getEnemiesInRangeGAMEINN2 user.getThroneLevel(), user.trophies, user.gold, user.mana, excludedQueryIds, newSlotsCount, (err, users) ->
            if err
                util.log '[ERROR] getEnemiesInRange ' + err + ' at generateNewMapSlots'
            users = rand.arrayShuffle users

            i = 0
            while i < newSlotsCount
                currentLocationId = prevMapSlotsCount + i + 1
                if npc[currentLocationId]?
#                    util.log 'Push boss ' + currentLocationId
                    user.map.push({
                        user: npc[currentLocationId],
                        locationId: currentLocationId,
                        occupied: true
                    })
                else if users[i]?
#                    util.log 'Push random user ' + currentLocationId
                    user.map.push({
                        user: users[i]._id,
                        locationId: currentLocationId,
                        occupied: true
                    })
                else
                    util.log '[ERROR] Not enough users to generate map slots with enemies ' + currentLocationId + 'username ' + user.username + ' usersgenerated ' + users.length
                    user.map.push({
                        user: null,
                        locationId: currentLocationId,
                        occupied: false
                    })
                i++

            user.save (err, obj) ->
                if err?
                    util.log '[ERROR] Saving user ' + err + ' generateNewMapSlots'
                    return cb user
                else
                    mm.UserProfile.userWithMap(obj._id, cb)

UserProfile.methods.updateMap = (invasionTimes, rewardTimes, isInit, cb) ->
    user = @

#    util.log 'updating map for user ' + user.display_name
    if invasionTimes > 0
        if (invasionTimes == user.getMaxInvasionTryCount())
            user.timers.invasion = Date.now()
        else
            user.timers.invasion += invasionTimes * INVASION_INTERVAL * 1000

    if rewardTimes > 0
        if (rewardTimes == user.getMaxRewardTryCount())
            user.timers.reward = Date.now()
        else
            user.timers.reward += rewardTimes * REWARD_INTERVAL * 1000

    if rewardTimes > 0 or invasionTimes > 0 or isInit
        user.save (err, obj) ->
            if err?
                util.log '[ERROR] Saving user ' + err + ' at updateMap'
                return cb user

            mm.UserProfile.userWithMap(obj._id, cb)
    else
        mm.UserProfile.userWithMap(user._id, cb)

UserProfile.statics.userWithMap = (id, cb) ->
    mm.UserProfile.findById(id).populate('map.user').exec (err, obj) ->
        if err?
            util.log '[ERROR] Getting userWithMap ' +  err

        cb obj

UserProfile.methods.getInvasionState = (enemiesCount, maxEnemiesCap) ->
    rate = enemiesCount / maxEnemiesCap
    chance = 16.0035*Math.pow(Math.E, -4.21741*rate)
    if chance >= rand.randomFloatRange(0, 100)
#        util.log '-> invasion is HERE'
        return true
#    util.log '-> invasion MISSED'

    return false

UserProfile.methods.getRewardState = () ->
    if REWARD_CHANCE >= rand.randomRange(0, 100)
        return true

    return false

UserProfile.methods.getRewardValue = () ->
    return rand.randomRange(MIN_REWARD_VALUE, MAX_REWARD_VALUE+1)

UserProfile.methods.invadeSlot = (locationId, enemy) ->
    # console.log 'invade slot ' + locationId + ' ' + enemy._id
    if @map[locationId - 1].locationId == locationId
        @map[locationId - 1].user = enemy._id
        @map[locationId - 1].defeated = false
        @map[locationId - 1].occupied = true
    else
        util.log('[WARN] Map location should be choose automatically when invade occur')
        for m, index in @map
            if m.locationId == locationId
                @map[index].user = enemy._id
                @map[index].defeated = false
                @map[index].occupied = true
                break

UserProfile.methods.rewardSlot = (locationId) ->
    if @map[locationId - 1].locationId == locationId
#        util.log 'adding rubies on location ' + locationId
        @map[locationId - 1].rubies = @getRewardValue()
    else
        util.log('[WARN] Map location should be choose automatically when reward occur')
        for m, index in @map
            if m.locationId == locationId
                @map[locationId - 1].rubies = @getRewardValue()
                break


UserProfile.methods.refillMapSlots = (balconomy, mapSlotsCount, mapUserIds, explorerLevel, isInit, cb) ->
#    util.log '-> REFILL MAP SLOTS TRY'
    user = @
    invasionTimes = user.getInvasionTimes()
    rewardTimes = user.getRewardTimes()

    excludedQueryIds = mapUserIds
    excludedQueryIds.push user._id

    async.series [
        (callback) ->
#            util.log 'Enemies refill'
            if (invasionTimes > 0)
                refillCap = balconomy.getRadarRefillCap(explorerLevel)
#                util.log '-> explorer level ' + explorerLevel
#                util.log '-> enemy refill cap ' + refillCap
                enemiesCount = user.getMapEnemyCount()
#                util.log '-> enemies on map ' + enemiesCount
                if enemiesCount < refillCap
                    refillMapSlotsCount = refillCap - enemiesCount
#                    util.log '-> slots to refill ' + refillMapSlotsCount


                    mm.UserProfile.getEnemiesInRangeGAMEINN2 user.getThroneLevel(), user.trophies, user.gold, user.mana, excludedQueryIds, refillMapSlotsCount, (err, enemies) ->
                        if err
                            util.log '[ERROR] getEnemiesInRange ' + err + ' at refillMapSlots'
                            callback(0,0)
                        enemies = rand.arrayShuffle enemies

                        invasionIndexId = 0
                        invasionCounter = invasionTimes
                        enemyIndex = enemies.length - 1
                        invasionPossibleLocations = user.getMapInvasionLocations(refillCap)
                        #                util.log '-> ' + JSON.stringify user.map, null, 2
                        while invasionCounter > 0 and refillMapSlotsCount > 0 and enemyIndex >= 0
                            invasionCounter--
                            if (user.getInvasionState(enemiesCount, refillCap))
                                user.calculateLootCartResources(user.getDefeatedCastles(), user.timers.invasion + ((invasionTimes - invasionCounter) * INVASION_INTERVAL * 1000), balconomy.get())
                                user.invadeSlot(invasionPossibleLocations[invasionIndexId], enemies[enemyIndex])
                                enemiesCount++
                                enemyIndex--
                                refillMapSlotsCount--
#                                util.log '-> current location index ' + invasionIndexId
#                                util.log '-> before slice: ' + JSON.stringify invasionPossibleLocations
                                invasionPossibleLocations.splice(invasionIndexId, 1)
#                                util.log '-> after slice: ' + JSON.stringify invasionPossibleLocations
                                invasionIndexId = if invasionIndexId < invasionPossibleLocations.length then invasionIndexId else 0
#                                util.log '-> next location index ' + invasionIndexId
                            else
                                invasionIndexId = if invasionIndexId + 1 < invasionPossibleLocations.length then invasionIndexId + 1 else 0

#                            util.log 'invasionCounter ' + invasionCounter + 'refillMapSlotsCount ' + refillMapSlotsCount + 'enemyIndex ' + enemyIndex

                        #                util.log '-> ' + JSON.stringify user.map, null, 2
                        callback(0, 0)
                else
#                    util.log '-> reffill not needed max cap is here'
                    callback(0, 0)
            else
#                util.log '-> ' + (Date.now() - user.timers.invasion) / 1000 / 60 + ' minutes after last invasion for user ' + user.display_name
                callback(0, 0)
        (callback) ->
            if isInit

                newExcludedQueryIds = []
                newExcludedQueryIds.push user._id

                slotsLocationToRefresh = []
                slotAssociation = balconomy.getSlotAssociation()
                bossLocations = balconomy.getBossLocations()
                #console.log 'slots:' + user.map
                
                for m, index in user.map
                    if not m.defeated and m.occupied
                        cloudId = slotAssociation[m.locationId]
            #            console.log(cloudId + ' ' + m.locationId);
                        if (user.cloud.indexOf(cloudId) < 0 and bossLocations.indexOf(m.locationId) < 0)
                            slotsLocationToRefresh.push m.locationId
                        else
                            newExcludedQueryIds.push m.user
                    else if m.user?
                        newExcludedQueryIds.push m.user

                if slotsLocationToRefresh.length > 0
                    mm.UserProfile.getEnemiesInRangeGAMEINN2 user.getThroneLevel(), user.trophies, user.gold, user.mana, newExcludedQueryIds, slotsLocationToRefresh.length, (err, enemies) ->
                        if err
                            util.log '[ERROR] getEnemiesInRange ' + err + ' at refillMapSlots'
                            callback(0, 0)
                        enemyIndex = enemies.length - 1
                        for slotLocation in slotsLocationToRefresh
                            if enemyIndex < 0
                                break;
                            user.invadeSlot(slotLocation, enemies[enemyIndex])
                            enemyIndex--
                        callback(0, 0)
                else
                    callback(0, 0)
            else
                callback(0, 0)
        (callback) ->
#            util.log 'Reward Refill'
            if (rewardTimes > 0)
                refillCap = user.getMaxRewardCap()
#                util.log '-> reward refill cap ' + refillCap
                currentRewardCount = user.getMapRewardCount()
                if currentRewardCount < refillCap
                    refillMapSlotsCount = refillCap - currentRewardCount
#                    util.log '-> reward slots to refill ' + refillMapSlotsCount
                    rewardCounter = rewardTimes
                    rewardPossibleLocations = user.getMapRewardLocations(refillCap)
#                    util.log 'rewardPossibleLocations ' + rewardPossibleLocations.length
                    rewardIndexId = 0
                    while rewardCounter > 0 and refillMapSlotsCount > 0 and rewardPossibleLocations.length > 0
                        rewardCounter--
                        if (user.getRewardState())
                            user.rewardSlot(rewardPossibleLocations[rewardIndexId])
                            refillMapSlotsCount--
#                            util.log '-> current location index ' + rewardIndexId
#                            util.log '-> before slice: ' + JSON.stringify rewardPossibleLocations
                            rewardPossibleLocations.splice(rewardIndexId, 1)
#                            util.log '-> after slice: ' + JSON.stringify rewardPossibleLocations
                            rewardIndexId = if rewardIndexId < rewardPossibleLocations.length then rewardIndexId else 0
#                            util.log '-> next location index ' + rewardIndexId
                        else
                            rewardIndexId = if rewardIndexId + 1 < rewardPossibleLocations.length then rewardIndexId + 1 else 0

#                        util.log 'rewardCounter ' + rewardCounter + 'refillMapSlotsCount ' + refillMapSlotsCount

                    callback(0, 0)
                else
#                    util.log '-> reffill reward not needed max cap is here'
                    callback(0, 0)
            else
#                util.log '-> ' + (Date.now() - user.timers.reward) / 1000 / 60 + ' minutes after last reward for user ' + user.display_name
                callback(0, 0)
    ],
    (err, results) ->
#        util.log 'Map update'
        if (err?)
            util.log '[ERROR] ' +  err + 'on updating map in async'
        else
            user.updateMap(invasionTimes ,rewardTimes, isInit, cb)


UserProfile.methods.isBattleOnline = (balconomy, cb) ->
    battle = @activeBattle

    if @profileType != 'PLAYER'
        return cb null, false

    if battle == undefined || battle == null
        return cb null, false

    mm.FightHistory.findById battle, (err, fightHistory) ->
        if err?
            util.log '[ERROR] ' + err + ' on finding fightHistory by Id'
            return cb err, true

        if fightHistory == null
            return cb null, false

        timestamp = fightHistory.timestamp + balconomy.getFullTimeOfBattle() + 30000

        if timestamp < Date.now()
            fightHistory.endBattle balconomy, (err) ->
                if err?
                    util.log '[ERROR] ' + err + ' on endBattle callback'
                    return cb err, true

                return cb null, false
        else
            return cb null, true

UserProfile.methods.collectReward = (locationId, cb) ->
    locationId = parseInt(locationId)


    if @map[locationId - 1].locationId == locationId
#        util.log 'collecting rubies on location ' + locationId
        
        if @map[locationId - 1].rubies == 0
            util.log '[ERROR] Empty reward location collected'
            # attempted to collect empty tent!
            return new ex.ResetRequired "", 'Collect reward on empty field', locationId

        rubiesGot = @map[locationId - 1].rubies
        @currency.hard += rubiesGot
        @currency.hardBonus += rubiesGot
        @map[locationId - 1].rubies = 0

        GameInn.SendEvent 'COLLECT_RESOURCES', {userID: @._id, resources: [{type: 'RUBY', amount: rubiesGot, location: 'MAP'}]}, (err, data) ->
            if err?
                console.log err

    else
        util.log('[WARN] Map location should be aligned according to locationId')
        for m, index in @map
            if m.locationId == locationId
                if @map[locationId - 1].rubies == 0
                    # attempted to collect empty tent!
                    util.log '[ERROR] Empty reward location collected and location mismatch'
                    return new ex.ResetRequired "", 'Collect reward on empty field', locationId

                GameInn.SendEvent 'COLLECT_RESOURCES', {userID: @._id, resources: [{type: 'RUBY', amount: @map[index].rubies, location: 'MAP'}]}, (err, data) ->
                    if err?
                        console.log err

                @currency.hard += @map[index].rubies
                @currency.hardBonus += @map[index].rubies
                @map[index].rubies = 0
                break

    @save (err, obj) ->
        if err?
            util.log '[ERROR] saving user profile ' + err + ' at collectReward'
            return cb err

        return cb()
            
UserProfile.methods.getDefeatedCastles = () ->
    defeated = 0

    for m in @map
        if m.defeated
            defeated++
    
    return defeated

UserProfile.methods.getQuantityOfLootCartResources = (resourceType) ->
    user = @
    for resource in user.lootCart.lootCartResourcesList
        if(resource.resourceType == resourceType)
            return resource.quantity

    return 0

UserProfile.methods.setQuantityOfLootCartResources = (resourceType, quantity) ->
    user = @
    for resource in user.lootCart.lootCartResourcesList
        if(resource.resourceType == resourceType)
            resource.quantity = quantity
            return
    
    resource = {
        quantity: quantity
        resourceType: resourceType
    }

    user.lootCart.lootCartResourcesList.push resource
    return

UserProfile.methods.calculateLootCartResources = (defeatedCastles, timestamp, balconomy) ->
    user = @
    if(user.lootCart.lastLootCartCollectedTimestamp < timestamp)
        timeDifferenceInSeconds = (timestamp - user.lootCart.lastLootCartCollectedTimestamp) / 3600000
        castles = defeatedCastles
        calculatedTimestamp = timestamp

        goldMaxCapacity = balconomy.balance.lootCart.tentGoldProductionRate * defeatedCastles * balconomy.balance.lootCart.lootCartTimeToFill
        manaMaxCapacity = balconomy.balance.lootCart.tentManaProductionRate * defeatedCastles * balconomy.balance.lootCart.lootCartTimeToFill

        goldQuantity = user.getQuantityOfLootCartResources 'GOLD'
        manaQuantity = user.getQuantityOfLootCartResources 'MANA'

        goldQuantity += balconomy.balance.lootCart.tentGoldProductionRate * castles * timeDifferenceInSeconds
        manaQuantity += balconomy.balance.lootCart.tentManaProductionRate * castles * timeDifferenceInSeconds

        goldQuantity = Math.min(Math.max(goldQuantity, 0), goldMaxCapacity)
        manaQuantity = Math.min(Math.max(manaQuantity, 0), manaMaxCapacity)

        user.setQuantityOfLootCartResources 'GOLD', goldQuantity
        user.setQuantityOfLootCartResources 'MANA', manaQuantity

        user.lootCart.lastLootCartCollectedTimestamp = calculatedTimestamp

UserProfile.methods.startNewGame = () ->
    user = @

    # Closing game if open

    query = {"user": user._id, "game.end": null}
    mm.RetentionHistory.findOne query, (err, retHist) ->
        if err?
            util.log '[ERROR] Getting not closed retention from database at startNewGame'
            return
        if retHist
            retHist.closeGame user.last_user_activity, (err) ->
                if err?
                    util.log '[ERROR] Closing previous game at startNewGame'

    # Creating new retentionHistory entry for user

    query = {"user": user._id}
    mm.RetentionHistory.find query, (err, retentions) ->
        if err?
            util.log '[ERROR] Finding retentions at startNewGame'
            return
        else
            mm.RetentionHistory.create {
                user: user._id
                game: {
                    start: Date.now()
                    end: null
                    number: retentions.length + 1
                }
            }, (err, retentionHistory) ->
                if err?
                    util.log '[ERROR] Creating new game history at startNewGame'

                profile = user.toJSON()
#                mapIds = []
#                for slot in user.map
#                    mapIds.push(slot.user.valueOf())
#
#                mm.UserProfile.find {_id:{$in: mapIds}}, (err, playersOnMap) ->
#                    if err?
#                        console.log err
#                        profile.errorMongo = err
#                    else
#                        for slot in profile.map
#                            for playerOnMap in playersOnMap
#                                if slot.user == (""+playerOnMap.valueOf())
#                                    slot.user.resources = playerOnMap.castle.resourcesList
#                                    slot.user.throneLevel = playerOnMap.throneLevel

                GameInn.SendFile 'Retention/'+user._id+'_'+retentionHistory._id+".json", profile, (err, data) ->
                    if err?
                        console.log err
                return

UserProfile.methods.getGoldLimit = (balconomy) ->
    goldLimit = 0

    for room in @castle.roomsList
        if room.roomType == "TREASURY_VAULT"
            roomLevel = balconomy.getRoomParams room.roomType, room.roomLevel
            goldLimit += roomLevel.capacity
        else if room.roomType == "THRONE"
            goldLimit += balconomy.getThroneResourceLimit(room.roomLevel).GOLD

    return goldLimit

UserProfile.methods.getManaLimit = (balconomy) ->
    manaLimit = 0

    for room in @castle.roomsList
        if room.roomType == "MANA_POTION_STORAGE"
            roomLevel = balconomy.getRoomParams room.roomType, room.roomLevel
            manaLimit += roomLevel.capacity
        else if room.roomType == "THRONE"
            manaLimit += balconomy.getThroneResourceLimit(room.roomLevel).MANA

    return manaLimit

###
# remove hard - amount of hard to remove, if not sufficient returns cb false
###
UserProfile.methods.removeHard = (amount) ->
    
    if @currency.hard >= amount
        
        @currency.hard -= amount
        @currency.hardSpent += amount
        
        return true

    util.log '[ERROR] No hard sufficient to removeHard ' + @currency.hard + ' amount ' + amount
    return false

###
# add hard - amount of hard to add, bonus = true if this is bonus in game
###
UserProfile.methods.addHard = (amount, bonus) ->
    
    if amount <= 0
        util.log '[ERROR] add hard with minus value ' + amount
        return false
    @currency.hard += parseInt(amount)
    if bonus == true
        @currency.hardBonus += amount
    
    return true

UserProfile.methods.getRoomCount = (roomType) ->
    roomCount = 0
    for room in @castle.roomsList
        if room.roomType == roomType
            roomCount++

    return roomCount

UserProfile.methods.getNewLayoutId = () ->
    layoutID = 0
    for roomLayout in @castle.layout[@castle.activeLayout].rooms
        if roomLayout.roomID > layoutID
            return layoutID
        else
            layoutID++
    
    return layoutID

UserProfile.methods.addRawRoom = (roomId, roomType, roomLevel) ->
    layoutID = @getNewLayoutId()
    room = {
        name: roomId + layoutID,
        roomType: roomType,
        roomLevel: roomLevel,
        buildingStartTimestamp: "01/01/0001 00:00:00",
        lastCollectTime: "01/01/0001 00:00:00",
        boostFinishTime: "01/01/0001 00:00:00",
        startTime: "",
        layoutID: layoutID,
        endTime: "",
        upgradeType: "",
        resourceProdQuantity: 0
    }

    roomLayout = {
        roomID: layoutID,
        position: {
            x: -1,
            y: -1
        }
    }

    @castle.layout[@castle.activeLayout].rooms.splice(layoutID, 0, roomLayout)
    @castle.roomsList.push(room)

    return

UserProfile.methods.addBuildRoom = (roomId, roomType, x, y, buildingTimestamp, finishBuildingTimestamp) ->
    layoutID = @getNewLayoutId()
    room = {
        name: roomId + layoutID,
        roomType: roomType,
        roomLevel: 0,
        buildingStartTimestamp: timeutils.timestampToClientTimeformat(buildingTimestamp),
        lastCollectTime: timeutils.timestampToClientTimeformat(finishBuildingTimestamp),
        boostFinishTime: "01/01/0001 00:00:00",
        startTime: "",
        layoutID: layoutID,
        endTime: "",
        upgradeType: "",
        resourceProdQuantity: 0
    }

    roomLayout = {
        roomID: layoutID,
        position: {
            x: x,
            y: y
        }
    }

    @castle.layout[@castle.activeLayout].rooms.splice(layoutID, 0, roomLayout)
    @castle.roomsList.push(room)

    return

UserProfile.methods.cancelBuildingRoom = (roomId) ->
    room = @getRoom(roomId)

    if(room.roomLevel == 0)
        @removeRoom(roomId)
    else
        room.buildingStartTimestamp = '01/01/0001 00:00:00'

UserProfile.methods.removeRoom = (roomId) ->
    room = @getRoom(roomId)
    layoutId = room.layoutID

    for item, index in @castle.roomsList
        if item.name == roomId
            @castle.roomsList.splice(index, 1)
            break
    
    for layout in @castle.layout
        for item, index in layout.rooms
            if item.roomID == layoutId
                layout.rooms.splice(index, 1)
                break

#UserProfile.methods.changeResource = (amount, resourceType) ->
#    if @castle.resourcesList?
#        for resource in @castle.resourcesList
#            if resource.resourceType == resourceType
#                resource.quantity += amount
#                resource.quantity = Math.max resource.quantity, 0
#                return true
#
#    util.log '[WARNING] Cannot find resourceType or resourceList'
#    return false

UserProfile.methods.removeResourceFromStorage = (resourceQuantity, resourceType) ->
    for resource in @castle.resourcesList
        if(resource.resourceType == resourceType)
            if(resource.quantity >= resourceQuantity)
                resource.quantity -= resourceQuantity
                return true
            else
                return false
        
    return false

UserProfile.methods.addResourceToStorage = (resourceQuantity, resourceType, balconomy) ->
    for resource in @castle.resourcesList
        if(resource.resourceType == resourceType)
            resource.quantity += resourceQuantity
            if resourceType == 'GOLD'
                resource.quantity = Math.min(resource.quantity, @getGoldLimit(balconomy))
                return true
            else if resourceType == 'MANA'
                resource.quantity = Math.min(resource.quantity, @getManaLimit(balconomy))
                return true
    return false

UserProfile.methods.getResourceFromStorages = (resourceType) ->
    for resource in @castle.resourcesList
        if(resource.resourceType == resourceType)
            return resource.quantity

    util.log '[ERROR] Cannot find resource of type ' + resourceType + ' for user ' + @_id
    return 0

###
# boostRoomProduction - room to boost
###
UserProfile.methods.boostRoomProduction = (room) ->

    for userRoom in @castle.roomsList
        if(userRoom.name == room.name)
            # add 24 h
            userRoom.boostFinishTime = timeutils.timestampToClientTimeformat(Date.now() + 86400000)
           
            return true
    util.log '[ERROR] BoostRoomProduction room not found ' + room.name + '  for user: ' + @_id
    return false

###
# finishRoomProduction - room to finish
###

UserProfile.methods.finishRoomProduction = (room) ->
    
    for userRoom in @castle.roomsList
        if(userRoom.name == room.name)
            userRoom.roomLevel++
            userRoom.buildingStartTimestamp = "01/01/0001 00:00:00" # timeutils.timestampToClientTimeformat(0) # "01/01/0001 00:00:00"
            # userRoom.endTime = null
            return true

    util.log '[ERROR] finishRoomProduction room not found for user: ' + @_id
    return false

UserProfile.methods.resetCollectTime = (room) ->

    for userRoom in @castle.roomsList
        if(userRoom.name == room.name)
            userRoom.lastCollectTime = timeutils.timestampToClientTimeformat(Date.now()) # "01/01/0001 00:00:00"
            return true

    util.log '[ERROR] resetCollectTime room not found for user: ' + @_id
    return false
    

UserProfile.methods.finishAmmoImmediately = () ->
    
    if (@castle.ammoProductionList.length == 0)
        util.log '[ERROR] Attempting to finish ammo but production list is empty!'
        return false # no production list to finish!
    
    # we set the date way back, because client will start sending FinishProjectile for every finished projectile
    @castle.ammoProductionStartTimestamp = "01/01/1990 00:00:00"
    
    return true

    
UserProfile.methods.finishProjectileResearchImmediately = () ->
    
    if (@castle.ammoResearch.projectileLevel == 0)
        util.log '[ERROR] Attempting to finish ammo research but research is empty!'
        return false # no research to finish!
    
    # check researchStartTimestamp to now span
    # calculate resources needed
    for ammo in @castle.ammoLevelsList
        if ammo.projectileId == @castle.ammoResearch.projectileId
            ammo.projectileLevel++
            @.upgradeExistingProjectiles(ammo.projectileId)
            break
    
    # MR: empty research object
    @castle.ammoResearch.projectileLevel = 0
    @castle.ammoResearch.projectileId = ""
    return true

UserProfile.methods.upgradeExistingProjectiles = (projectileId) ->
    
    if projectileId is null
        util.log '[ERROR] Attempting to upgrade nonexisting ammo!'
        return false # no research to finish!
    
    # check researchStartTimestamp to now span
    # calculate resources needed

    #: check for ownership when donating is implemented

    for ammo in @castle.ammoStoredList
        if ammo.projectileId == projectileId
            ammo.projectileLevel++
        
    return true


UserProfile.methods.getBuildersCount = () ->
    builders = 0
    for userRoom in @castle.roomsList
        if(userRoom.roomType == 'BUILDER')
            builders++

    return builders

UserProfile.methods.getFreeBuildersCount = () ->
    builders = @getBuildersCount()
    for userRoom in @castle.roomsList
        if(userRoom.buildingStartTimestamp != '01/01/0001 00:00:00')
            builders--

    return builders

UserProfile.methods.isAnyProjectileResearching = () ->
    return @castle.ammoResearch.projectileLevel != 0

UserProfile.methods.getAmmoLevel = (projectileId) ->
    for ammo in @castle.ammoLevelsList
        if ammo.projectileId == projectileId
            return ammo.projectileLevel

    return 0

UserProfile.methods.startResearchProjectile = (projectileId, projectileLevel) ->
    @castle.ammoResearch.projectileLevel = projectileLevel
    @castle.ammoResearch.projectileId = projectileId
    @castle.ammoResearch.researchStartTimestamp = timeutils.timestampToClientTimeformat(Date.now())

UserProfile.methods.getArmoryMaxLevel = () ->
    level = 0
    for room in @castle.roomsList
        if room.roomType == "ARMORY"
            level = Math.max(level, room.roomLevel)

    return level

UserProfile.methods.setRoomPosition = (layoutId, x, y) ->
    for layout in @castle.layout[@castle.activeLayout].rooms
        if(layout.roomID == layoutId)
            layout.position.x = x
            layout.position.y = y
            return true

    roomLayout = {
        roomID: layoutID,
        position: {
            x: x,
            y: y
        }
    }

    for item, index in @castle.layout[@castle.activeLayout].rooms
        if(item.roomId > layoutID)
            @castle.layout[@castle.activeLayout].rooms.splice(index - 1, 0, roomLayout)
            return false

    @castle.layout[@castle.activeLayout].rooms.push(roomLayout)
    return false

UserProfile.methods.addAmmoToProduction = (projectileId, amount, productionStartTimestamp) ->
    if not projectileId? or (amount < 1)
        return false

    if @castle.ammoProductionList.length
        if @castle.ammoProductionList[@castle.ammoProductionList.length - 1].projectileId == projectileId
            @castle.ammoProductionList[@castle.ammoProductionList.length - 1].projectileAmount += amount
        else
            ammo = {}
            ammo.projectileId = projectileId
            ammo.projectileAmount = amount
            @castle.ammoProductionList.push(ammo)

    else
        ammo = {}
        ammo.projectileId = projectileId
        ammo.projectileAmount = amount
        @castle.ammoProductionList.push(ammo)

    if @castle.ammoProductionStartTimestamp == '01/01/0001 00:00:00'
        @castle.ammoProductionStartTimestamp = timeutils.timestampToClientTimeformat(productionStartTimestamp)

    return true

UserProfile.methods.flipRoom = (room) ->
    
    for userRoom in @castle.roomsList
        if(userRoom.name == room.name)
            
            if(userRoom.roomType.indexOf("_LEFT", this.length - "_LEFT".length) != -1)
                userRoom.roomType = room.roomType.replace(/_LEFT/g, "_RIGHT")
            else if (userRoom.roomType.indexOf("_RIGHT", this.length - "_RIGHT".length) != -1)
                userRoom.roomType = room.roomType.replace(/_RIGHT/g, "_LEFT")
            else
                # non-flippable room!
                util.log '[ERROR] flipRoom room not flippable for user: ' + @_id + ' room ' + room.id
                return false

            return true

    util.log '[ERROR] flipRoom room not found for user: ' + @_id + ' room ' + room.id
    return false

UserProfile.methods.isCloudUncovered = (cloudId) ->
    return @cloud.indexOf(cloudId) != -1

UserProfile.methods.uncoverCloud = (cloudId) ->
    @cloud.push(cloudId)
    
UserProfile.methods.finishProjectileProduction = (projectileId, balconomy) ->
    user = @
    
    productionTimestamp = timeutils.clientTimeformatToTimestamp(@castle.ammoProductionStartTimestamp)

    for ammo in @castle.ammoLevelsList
        if ammo.projectileId == projectileId
            #ammo.projectileLevel is our level

            projectileParam = balconomy.getProjectileParams(projectileId, ammo.projectileLevel)
            constructionTime = projectileParam.constructionTime

            if @castle.ammoProductionList[0].projectileId == projectileId
                
                # check if viable
                endproduction = productionTimestamp + constructionTime * 1000
                calculatedendprod = Date.now() + 10000
                if ( endproduction > calculatedendprod )
                    util.log '[ERROR] ProjectileProduction timestamp not viable for user: ' + @username + ', endproduction is: ' + timeutils.timestampToClientTimeformat(endproduction) + ', calculated is: ' +  timeutils.timestampToClientTimeformat(calculatedendprod)
                    return false
                

                # alter ammoStoredList
                stored = false
                
                for storedProjectiles in @castle.ammoStoredList
                    if (projectileId == storedProjectiles.projectileId) and (storedProjectiles.projectileLevel == ammo.projectileLevel)
                        #there are such projectiles on the stored list with right level
                        #increase amount of them
                        storedProjectiles.projectileAmount += 1
                        stored = true
                if not stored
                    # there are no such stored projectiles on list
                    #add a projectile to stored list with present projectile level
                    newStoredProjectileGroup = {}
                    newStoredProjectileGroup.projectileId = projectileId
                    newStoredProjectileGroup.projectileAmount = 1
                    newStoredProjectileGroup.projectileLevel = ammo.projectileLevel
                    newStoredProjectileGroup.ownerId = @._id
                    @castle.ammoStoredList.push(newStoredProjectileGroup)
                

                # alter ammoProductionList
                if (@castle.ammoProductionList[0].projectileAmount > 1)
                    @castle.ammoProductionList[0].projectileAmount -= 1
                else
                    @castle.ammoProductionList.shift()

                if @castle.ammoProductionList.length == 0
                    # reset ammoProductionStartTimestamp
                    #util.log '[INFO] Ammo production timestamp set to 01/01/0001 00:00:00 (reset)'
                    @castle.ammoProductionStartTimestamp = '01/01/0001 00:00:00'
                else
                    # alter ammoProductionStartTimestamp
                    nextProdTS = productionTimestamp + constructionTime * 1000
                    @castle.ammoProductionStartTimestamp = timeutils.timestampToClientTimeformat(nextProdTS)
                    #util.log '[INFO] Projectile produced at: ' + productionTimestamp + ', which is: ' + timeutils.timestampToClientTimeformat(productionTimestamp)
                    #util.log '[INFO] pushing ammoProductionStartTimestamp to ' + nextProdTS + ', which is: ' + @castle.ammoProductionStartTimestamp + ', because production list is not empty.'

                return true

            # this is not a first projectile on the list
            util.log ' [ERROR] finishProjectileProduction attempting to finish not a first projectile on a list]'
            return false

    # projectileId not found in ammoLevelsList!
    util.log '[ERROR] projectileId not found in ammoLevelsList! user ' + user.username
    return false


UserProfile.methods.removeProjectile = (projectileId) ->
    user = @
    altered = false
    
    nonEmptyAmmoList = []

    for ammo in @castle.ammoStoredList
        if ammo.projectileId == projectileId
            ammo.projectileAmount -= 1
            # util.log '[INFO] removeProjectile Removed ' + projectileId + ' from ammoStoredList of ' + user.username
            altered = true
        
        if ammo.projectileAmount > 0
            nonEmptyAmmoList.push(ammo)
        
    @castle.ammoStoredList = nonEmptyAmmoList

    if altered
        return true
    
    return false

UserProfile.methods.setTutorialState = (value) ->

    if @currentTutorialState == 1
        return true
    if value?
        @currentTutorialState = value
        return true

    util.log '[ERROR] currentTutorialState field not found, user ' + @username
    return false

UserProfile.methods.updateStoryProgressList = (eventId) ->

    for event in @castle.storyProgressList
        if event.eventId == eventId
            event.eventCounter += 1
            if eventId == 'WE_CLAIM_THIS_LAND_BACK'
                if event.eventCounter > 4
                    event.occured = true
            else if eventId == 'NO_PROJECTILES_UPGRADED'
                if event.eventCounter > 2
                    event.occured = true
            else
                event.occured = true
            
            return true
    
    # no such event was found!
    return false

UserProfile.methods.AddProjectile = (projectileId, amount) ->
    user = @
    added = false

    for proj in user.castle.ammoStoredList
        if proj.projectileId == projectileId
            added = true
            proj.projectileAmount += amount
            break

    if not added
        user.castle.ammoStoredList.push
            "ownerId" : user._id
            "projectileAmount" : amount
            "projectileLevel" : user.getAmmoLevel(projectileId)
            "projectileId" : projectileId



UserProfile.methods.removeProjectileFromQueue = (index) ->
    if ( (index < 0) or (index is null) or (index >= @castle.ammoProductionList.length) )
        return false
    
    if @castle.ammoProductionList[index].projectileAmount > 1
        # only decrease ammo amount and job done
        @castle.ammoProductionList[index].projectileAmount -= 1
        return true

    else # removing last projectile, need to splice and possibly connect two

        if ( (index > 0) and (index < @castle.ammoProductionList.length - 1) ) # not on boundary
            if @castle.ammoProductionList[index-1].projectileId == @castle.ammoProductionList[index+1].projectileId
                #need to connect two of them - add next to previous entry
                @castle.ammoProductionList[index-1].projectileAmount += @castle.ammoProductionList[index+1].projectileAmount
                # remove this and next entry
                @castle.ammoProductionList.splice(index, 2)
                return true

            else # no need to connect
                @castle.ammoProductionList.splice(index, 1)
                return true
            
        else # no need to connect
            @castle.ammoProductionList.splice(index, 1)
            return true

UserProfile.methods.incrementAdsCount = (balconomy) ->
    if(timeutils.clientTimeformatToTimestamp(@ads.adsFirstWatchTimestamp) + (balconomy.getAdsHoursToResetLimit() * 60 * 60 * 1000) < Date.now())
        @ads.adsCounter = 0
        @ads.adsFirstWatchTimestamp = timeutils.timestampToClientTimeformat(Date.now())

    if(@ads.adsCounter >= balconomy.getAdsLimit())
        return false

    @ads.adsCounter++
    return true

UserProfile.methods.incrementFreeGemsAdsCount = (balconomy) ->
    if(timeutils.clientTimeformatToTimestamp(@ads.freeGemsAdsFirstWatchTimestamp) + (balconomy.getFreeGemsAdsHoursToResetLimit() * 60 * 60 * 1000) < Date.now())
        @ads.freeGemsAdsCounter = 0
        @ads.freeGemsAdsFirstWatchTimestamp = timeutils.timestampToClientTimeformat(Date.now())

    if(@ads.freeGemsAdsCounter >= balconomy.getFreeGemsAdsCountLimit())
        return false

    @ads.freeGemsAdsCounter++
    return true

UserProfile.methods.finishAmmoCommercial = (reduceTimeInSeconds) ->
    
    if (@castle.ammoProductionList.length != 0)
        @castle.ammoProductionStartTimestamp = timeutils.timestampToClientTimeformat(timeutils.clientTimeformatToTimestamp(@castle.ammoProductionStartTimestamp) - reduceTimeInSeconds * 1000)

UserProfile.methods.addFreeGemsCommercial = (balconomy) ->
    @.addHard(balconomy.getFreeGemsAdsReward())

UserProfile.methods.calculateAmmoProductionRemainTimeInSeconds = (balconomy) ->
    ammoProductionStartServerTimestamp = timeutils.clientTimeformatToTimestamp(@castle.ammoProductionStartTimestamp)
    timeDifferenceInSeconds = (Date.now() - ammoProductionStartServerTimestamp) / 1000

    totalProductionTimeInSeconds = 0

    for producedAmmo in @castle.ammoProductionList
        for ammo in @castle.ammoLevelsList
            if ammo.projectileId == producedAmmo.projectileId
                projectileParams = balconomy.getProjectileParams(producedAmmo.projectileId, ammo.projectileLevel)
                totalProductionTimeInSeconds += projectileParams.constructionTime * producedAmmo.projectileAmount

    return totalProductionTimeInSeconds - timeDifferenceInSeconds


UserProfile.methods.SetLastNotificationVisible = (value) ->

    if value?
        @last_notification_visible = value
        return true
    
    return false

UserProfile.methods.IsTutorialOn = (value) ->
    return @currentTutorialState != 1

UserProfile.methods.getAchievement = (achievementId) ->
    for achievement in @achievements
        if achievement.id == achievementId
            return achievement

    console.log '[ERROR] Cannot find user achievement ' + achievementId
    return null


UserProfile.methods.setAchievementProgress = (id, currentProgress) ->
    for achievement in @achievements
        if achievement.id == id
            if currentProgress > achievement.currentProgress
                achievement.currentProgress = currentProgress
            return true

    console.log '[WARN] Couldnt find achievement in setAchievementProgress ' + id
    return false

UserProfile.methods.incrementAchievementProgress = (id, addProgress) ->
    for achievement in @achievements
        if achievement.id == id
            achievement.currentProgress += addProgress
            return true

    console.log '[WARN] Couldnt find achievement in incrementAchievementProgress ' + id
    return false

UserProfile.methods.refillResources = (balconomy) ->
    for resource in @castle.resourcesList
        if resource.resourceType == 'GOLD'
            resource.quantity = @getGoldLimit(balconomy)
        else if resource.resourceType == 'MANA'
            resource.quantity = @getManaLimit(balconomy)
