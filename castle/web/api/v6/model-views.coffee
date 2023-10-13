# Defines model views. In other words converts models in a specific context
# (e.g. config, current user) and produces JavaScript objects which are
# returned by the API.
mongoose = require 'mongoose'
ts = require '../../util/time'
util = require 'util'


ObjectId = mongoose.Types.ObjectId


DEFAULT_ERROR_MESSAGES =
    enum: 'Value not in set'
    min: 'Value too small'
    max: 'Value too large'
    regexp: 'Value did not pass a regular expression test'


class ModelView
    ERROR_MESSAGES: {}

    # `doc`: Document/model instance
    # `ctx`: Context (e.g. configuration, current user etc.)
    constructor: (@doc, @ctx) ->

    # Supports callback-based calls for async operations as well as synchronous
    # call.
    export: (cb) ->
        if cb?
            return cb null, null

        return null

    # Processes validation errors returned by Mongoose and produces object for
    # inclusion in API error response.
    getErrorMessages: (errors) ->
        data = {}
        messages = @ERROR_MESSAGES

        for field, err of errors
            if field of messages and err.type of messages[field]
                data[field] = messages[field][err.type]
            else
                if err.type of DEFAULT_ERROR_MESSAGES
                    data[field] = DEFAULT_ERROR_MESSAGES[err.type]
                else
                    data[field] = 'Invalid value'

        return data

#: for now it's UserProfile mockup later data should be filtered (f.e. exclude password)
UserProfile = class extends ModelView
    ERROR_MESSAGES:
        email:
            regexp: 'The e-mail is not valid'
        username:
            regexp: 'Requires at least 3 characters (accepts alfanumerics, underscore and single dot)'

    export: (cb) ->
        obj = JSON.parse(JSON.stringify(@doc));

        obj.username = @doc.display_name
        obj.userId = @doc.username
        
        obj.password = undefined
        obj.last_user_activity = undefined
        obj.last_profile_data_update = undefined
        obj.flags = undefined
        obj.roles = undefined
        obj.isAdmin = undefined
        obj.isAnonymous = undefined
        obj.nid = undefined
        obj.joined = undefined
        obj.resetRequired = undefined
        obj.access_token = undefined
        obj.info = undefined
        map = @exportMap()

        obj.map = map

        if cb?
            return cb null, obj

        return obj

    UserProfile = class extends ModelView
    ERROR_MESSAGES:
        email:
            regexp: 'The e-mail is not valid'
        username:
            regexp: 'Requires at least 3 characters (accepts alfanumerics, underscore and single dot)'

    exportUserData: (cb) ->
        obj = JSON.parse(JSON.stringify(@doc));

        obj.username = @doc.display_name
        obj.userId = @doc.username

        obj.password = undefined
        obj.last_user_activity = undefined
        obj.last_profile_data_update = undefined
        obj.flags = undefined
        obj.roles = undefined
        obj.isAdmin = undefined
        obj.isAnonymous = undefined
        obj.nid = undefined
        obj.joined = undefined
        obj.resetRequired = undefined
        map = @exportMap()
        obj.castle = UserProfile.apllyResourceToStealInCastle(@doc, @ctx.balconomy, @ctx.user.getThroneLevel())
        obj.map = map

        if cb?
            return cb null, obj

        return obj

    exportEnemyData: (cb) ->
        obj =
            _id: @doc._id
            username: @doc.display_name
            userId: @doc.username
            profileType: @doc.profileType
            trophies: @doc.trophies
            level: @doc.level
            throneLevel: @doc.throneLevel
    #            gold: UserProfile.getUserResourceToStealSum(@doc, 'gold', @ctx)
    #            mana: UserProfile.getUserResourceToStealSum(@doc, 'mana', @ctx)
            castle: UserProfile.apllyResourceToStealInCastle(@doc, @ctx.balconomy, @ctx.user.getThroneLevel())

        if cb?
            return cb null, obj

        return obj


    @apllyResourceToStealInCastle = (user, balconomy, userThroneLevel) ->
        resourceStealingRatesMultiplierParams = balconomy.getResourceStealingRatesMultiplier(userThroneLevel)

        resourceStealingRatesMultiplier = 1
        if(resourceStealingRatesMultiplierParams != null)
            resourceStealingRatesMultiplier = resourceStealingRatesMultiplierParams.multiplier

        castle = user.castle
        for room, index in castle.roomsList
            if room.roomType in ['TAX_COLLECTOR', 'ALCHEMICAL_WORKSHOP']
                castle.roomsList[index]['resourceProdQuantity'] = @getResourceToStealCollector(room, balconomy) * resourceStealingRatesMultiplier

        for resource, index in castle.resourcesList
            resourceType = resource.resourceType.toLowerCase()
            castle.resourcesList[index].quantity = @getResourceToStealAllStorages(user, resourceType, balconomy) * resourceStealingRatesMultiplier

        return castle

    @calculateResourceInRoom: (room, balconomy, date) ->
        normalSpan = 0
        boostedSpan = 0
        date = if date then date else Date.now()
        date /= 1000
        boostFinishTime = (ts.clientTimeformatToTimestamp room.boostFinishTime) / 1000
        lastCollectTime = (ts.clientTimeformatToTimestamp room.lastCollectTime) / 1000

        if lastCollectTime < date
            if lastCollectTime >= boostFinishTime
                #normal production rate
                normalSpan = date - lastCollectTime
            else if date <= boostFinishTime
                #boosted production rate all the time
                boostedSpan = date - lastCollectTime
            else if lastCollectTime < boostFinishTime and date > boostFinishTime
                #partly boosted and partly normal production rate
                boostedSpan = boostFinishTime - lastCollectTime
                normalSpan = date - boostFinishTime

        roomParams = balconomy.getRoomParams room.roomType, room.roomLevel
        normalProductionSum = normalSpan * roomParams.productionRate
        boostedProductionSum = boostedSpan * roomParams.productionRate * balconomy.getProductionBoost()
        resourcesSum = room.resourceProdQuantity + Math.floor(normalProductionSum + boostedProductionSum)
        resourcesSum = Math.min resourcesSum, roomParams.capacity

        return resourcesSum

    @getResourceToStealAllStorages = (user, resourceType, balconomy) ->
#        if user.nid == 1
#            util.log '[WARN] storage stealing rate ' + balconomy.getStorageRoomStealingRate()
#            util.log '[WARN] ' + resourceType + ' ' + user[resourceType]
        return Math.ceil(balconomy.getStorageRoomStealingRate() * user[resourceType])

    @getResourceToStealCollector = (room, balconomy) ->
        return Math.ceil(balconomy.getProductionRoomStealingRate() * @calculateResourceInRoom(room, balconomy))

    @getResourceToStealAllCollectors = (roomsList, resourceType, balconomy, user) ->
        quantity = 0
        roomType = balconomy.getRoomTypeByResource(resourceType)
        for room in roomsList
            if roomType == room.roomType
                quantity += @getResourceToStealCollector(room, balconomy)

#        if user.nid == 1
#            util.log '[WARN] roomType ' + roomType
#            util.log '[WARN] collector sum ' + quantity

        return quantity

    @getUserResourceToStealSum = (user, resourceType, balconomy) ->
        totalInStorages = @getResourceToStealAllStorages(user, resourceType, balconomy)
        totalInCollectors = UserProfile.getResourceToStealAllCollectors(user.castle.roomsList, resourceType, balconomy, user)

        return (totalInCollectors + totalInStorages)

    exportMap: (cb) ->
        if cb?
            return cb null, @doc

        obj = []

        resourceStealingRatesMultiplierParams = @ctx.balconomy.getResourceStealingRatesMultiplier(@doc.getThroneLevel())

        resourceStealingRatesMultiplier = 1
        if(resourceStealingRatesMultiplierParams != null)
            resourceStealingRatesMultiplier = resourceStealingRatesMultiplierParams.multiplier

        for slot in @doc.toObject().map
            mapSlot =
                user: null
                locationId: slot.locationId
                occupied: slot.occupied
                defeated: slot.defeated
                rubies: slot.rubies
            if slot.user?
                gold = UserProfile.getUserResourceToStealSum(slot.user, 'gold', @ctx.balconomy) * resourceStealingRatesMultiplier
                mana = UserProfile.getUserResourceToStealSum(slot.user, 'mana', @ctx.balconomy) * resourceStealingRatesMultiplier

                mapSlot.user =
                    username: slot.user.display_name
                    userId: slot.user.username
                    profileType: slot.user.profileType
                    _id: slot.user._id
                    gold: gold
                    mana: mana
                    throneLevel: slot.user.throneLevel
                    trophies: slot.user.trophies
                    level: slot.user.level

            obj.push(mapSlot)

        return obj

exports.UserProfile = UserProfile

exports.FightHistory = class extends ModelView
    export: (cb) ->
        obj = []

        for history in @doc
            element =
                _id: history._id
                attacker:
                    userId: history.attacker.username
                    username: history.attacker.display_name
                defender:
                    userId: history.defender.username
                    username: history.defender.display_name
                timestamp: history.timestamp
                ammoList: history.ammoList
                attackerTrophies: history.attackerTrophies
                defenderTrophies: history.defenderTrophies
                attackerEarn: history.attackerEarn
                defenderEarn: history.defenderEarn
                resourcesList: history.resourcesList
                stars: history.stars
                percent: history.percent
                replay: history.replay
                revenge: history.revenge

            obj.push(element)

        if cb?
            return cb null, obj

        return obj

exports.RetentionHistory = class extends ModelView
    export: (cb) ->
        obj =
            _id: @doc._id
            user: @doc.user
            
        obj.games = []

        for game in @doc.games
            element =
                number: game.number
                start: game.start
                end: game.end

            obj.games.push(element)

        if cb?
            return cb null, obj

        return obj
        
exports.Leaderboard = class extends ModelView    
    export: (cb) ->
        obj = []
        for player, index in @doc
            data = 
                #liga <- jak będzie gotowa
                attacksWon: player.stats.attacksWon
                defencesWon: player.stats.defencesWon
                trophies: player.trophies
                userId: player._id
                display_name: player.display_name

            obj.push(data)

        if cb?
            return cb null, obj

        return obj