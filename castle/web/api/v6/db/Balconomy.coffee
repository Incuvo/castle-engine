mm = require './mongodb/models'
util    = require 'util'
mathCSharp = require './../../../util/math'

class Balconomy
    @_production_boost_multiplier: 2

    constructor: () ->
        @_balconomy = {}


    refreshBalconomy: () ->
        self = @
        mm.Balconomy.getLastVersion (balconomy) ->
            self._balconomy = balconomy
            util.log "[CASTLE API] Balconomy " + balconomy.version + " loaded from Mongo"
#            tkowalski: take only bosses with positive nid, negative is only to keep this accounts for future and change it to positive
            mm.UserProfile.find({profileType: 'NPC_BOSS', nid: {$gt: 0}}).sort({nid: 1}).exec (err, users) ->
                bosses = []
                for user in users
                    bosses.push {
                        bossSlotId: user.nid
                        bossLevel: user.getThroneLevel()
                    }
                self._balconomy.balance.bossLocations = bosses


    getRadarSlotRange: (explorerLevel) ->
        #When calculating previouse slot range for newly created user
        if explorerLevel == -1
            return 0
        radarRange = @getRadarRange explorerLevel
        if radarRange != null
            return radarRange.slotRange

        return 0

    getRadarRefillCap: (explorerLevel) ->
        radarRange = @getRadarRange explorerLevel
        if radarRange != null
            return radarRange.refillCap

        return 0

    getCloudPricesCurveDesc: () ->
        return @_balconomy.economy.cloudPricesCurveDesc

    getRadarRange: (explorerLevel) ->
        radarRanges = @_balconomy.balance.radarRanges
        if explorerLevel < 0 || (explorerLevel + 1) > radarRanges.length
            util.log '[ERROR] radar range for explorer level ' + explorerLevel + ' not found'
            return null
        if radarRanges[explorerLevel].level == explorerLevel
            return radarRanges[explorerLevel]

        util.log "[ERROR] Wrong balconomy structure: radarRanges level doesn't match explorer level !!!"
        return null


    get: () ->
        return @_balconomy
    
    getVersion: () ->
        return @_balconomy.version

    resolveCostCategoryId: (type) ->
        for resource in @_balconomy.config.costCategories
            if(resource.name == type)
                return resource.id

        return "none"

    resolveCostCategoryType: (id) ->
        for resource in @_balconomy.config.costCategories
            if(resource.id == id)
                return resource.name

        return "none"

    resolveRoomId: (type) ->
        switch type
            when "LABORATORY" then return "laboratory"
            when "ALCHEMICAL_WORKSHOP" then return "alchemicalWorkshop"
            when "AMMO_STORAGE" then return "ammoStorage"
            when "ARCHER" then return "archerRoom"
            when "ARMORY" then return "armory"
            when "BASE_ROOM" then return "baseRoom"
            when "BUILDER" then return "builder"
            when "CANNON" then return "cannonRoom"
            when "CATAPULT_WORKSHOP" then return "catapultWorkshop"
            when "EMPTY_ROOM" then return "emptyRoom"
            when "THRONE" then return "throneHall"
            when "ACADEMY_OF_MAGIC" then return "academyOfMagic"
            when "MANA_POTION_STORAGE" then return "manaPotionStorage"
            when "FORTIFICATIONS_ROOF" then return "fortificationsRoof"
            when "FORTIFICATIONS_ROOFTOP_LEFT", "FORTIFICATIONS_ROOFTOP_RIGHT" then return "fortificationsRooftop"
            when "FORTIFICATIONS_ROOM_LEFT", "FORTIFICATIONS_ROOM_RIGHT" then return "fortificationsRoom"
            when "FORTIFICATIONS_TOWER_LEFT", "FORTIFICATIONS_TOWER_RIGHT" then return "fortificationsTower"
            when "FORTIFICATIONS_WALL_LEFT", "FORTIFICATIONS_WALL_RIGHT" then return "fortificationsWall"
            when "FORTIFICATIONS_BRIDGE_LEFT", "FORTIFICATIONS_BRIDGE_RIGHT" then return "fortificationsBridge"
            when "FORTIFICATIONS_BIGTOWER" then return "fortificationsBigtower"
            when "FORTIFICATIONS_ROOF1" then return "fortificationsRoof1"
            when "FORTIFICATIONS_COPING" then return "fortificationsCoping"
            when "TAX_COLLECTOR" then return "taxCollector"
            when "TREASURY_VAULT" then return "treasuryVault"
            when "DEFENCE_FIELD_SPEED" then return "defenceFieldSpeed"
            when "SHOOTING_HOMING_MISSILE" then return "shootingHomingMissile"
            when "SHOOTING_ANTI_ALTILERY" then return "shootingAntiAltilery"
            when "SHOOTING_LASER_RAY" then return "shootingLaserRay"
            when "EXPLORER" then return "explorer"
            else return "none"

    getRoomParams: (roomType, level) ->
        id = @resolveRoomId roomType
        for room in @_balconomy.balance.roomParams
            if room.id == id
                for levels in room.roomLevels
                    if levels.level == level
                        return levels

        util.log '[ERROR] Couldnt find room params for roomType ' + roomType + ' level ' + level
                        
        return null

    getRoomDefinition: (roomType) ->
        id = @resolveRoomId roomType
        for room in @_balconomy.config.roomsDefinitions
            if room.id == id
                return room

        console.log '[WARNING] couldnt find room definition for roomType ' + roomType
                        
        return null

    getProjectileDefinition: (projectileId) ->
        for projectile in @_balconomy.config.projectilesDefinitions
            if projectile.id == projectileId
                return projectile

        console.log '[WARNING] couldnt find projectile definition for projectileId ' + projectileId
                        
        return null

    getProjectileParams: (projectileId, level) ->
        for projectile in @_balconomy.balance.projectileParams
            if projectile.id == projectileId
                for levels in projectile.projectileLevels
                    if levels.level == level
                        return levels

        console.log '[WARNING] couldnt find projectile params for projectileId ' + projectileId + ' level ' + level
                        
        return null

    getProjectileMaxLevel: (projectileId) ->
        level = 1
        for projectile in @_balconomy.balance.projectileParams
            if projectile.id == projectileId
                for levels in projectile.projectileLevels
                    if levels.level > level
                        level = levels.level
                return level

        util.log '[WARN] Couldnt find max projectile level for ' + projectileId
        return level

    getRoomTypeByResource: (resourceType) ->
        switch resourceType
            when 'gold' then return 'TAX_COLLECTOR'
            when 'mana' then return 'ALCHEMICAL_WORKSHOP'
            else return null

    getStorageRoomStealingRate: () ->
        return @_balconomy.economy.resourceStealingRates.storageRoomStealingRate

    getProductionRoomStealingRate: () ->
        return @_balconomy.economy.resourceStealingRates.productionRoomStealingRate

    getProductionBoost: () ->
        return Balconomy._production_boost_multiplier


    getInApps: () ->
        return @_balconomy.economy.gemsInApps.inApps

    getBundleInApps: () ->
        return @_balconomy.economy.bundleInApps.inApps

    getInAppPack: (inAppId) ->
        inApps = @getInApps()
        for ia in inApps
            if ia.InAppID == inAppId
                return ia

        bInApps = @getBundleInApps()
        for bia in bInApps
            if bia.InAppID == inAppId
                return bia

        util.log '[WARNING] In app pack: ' + inAppId + ' not found'
        return null

    getRoomLimits: (roomType, throneHallLevel) ->
        roomTypeId = @resolveRoomId(roomType)
        for roomLimit in @_balconomy.balance.roomLimits
            if roomLimit.roomTypeId == roomTypeId
                for throneHallLimit in roomLimit.throneLevelList
                    if throneHallLimit.hearthLevel == throneHallLevel
                        return throneHallLimit

        util.log '[WARNING] couldnt find room limit for roomType ' + roomTypeId + 'for throneHall level ' + throneHallLevel
        return null

    isFortificationRoom: (roomType) ->
        switch roomType
            when "FORTIFICATIONS_ROOF" then return true
            when "FORTIFICATIONS_ROOFTOP_LEFT" then return true
            when "FORTIFICATIONS_ROOFTOP_RIGHT" then return true
            when "FORTIFICATIONS_ROOM_LEFT" then return true
            when "FORTIFICATIONS_ROOM_RIGHT" then return true
            when "FORTIFICATIONS_TOWER_LEFT"then return true
            when "FORTIFICATIONS_TOWER_RIGHT" then return true
            when "FORTIFICATIONS_WALL_LEFT"then return true
            when "FORTIFICATIONS_WALL_RIGHT" then return true
            when "FORTIFICATIONS_BRIDGE_LEFT" then return true
            when "FORTIFICATIONS_BRIDGE_RIGHT" then return true
            when "FORTIFICATIONS_BIGTOWER" then return true
            when "FORTIFICATIONS_ROOF1" then return true
            when "FORTIFICATIONS_COPING" then return true
            else return false

    getExchangeCost: (quantity) ->
        a = @_balconomy.economy.exchangeGemsRateSettings.powerFunctionParamA
        b = @_balconomy.economy.exchangeGemsRateSettings.powerFunctionParamB
        c = @_balconomy.economy.exchangeGemsRateSettings.powerFunctionParamC

        return mathCSharp.roundNumber Math.pow(a * quantity + c, b)


    calculateCloudPricesCurveDesc: (value) ->
        a = @_balconomy.economy.cloudPricesCurveDesc.powerFunctionParamA
        b = @_balconomy.economy.cloudPricesCurveDesc.powerFunctionParamB
        c = @_balconomy.economy.cloudPricesCurveDesc.powerFunctionParamC
    
        result = Math.pow( (a * value + c), b ) / 100
        return Math.floor(result) * 100 # ROUND TO INT IN CLIENT MAY BE PROBLEMATIC!

    calculateImmediateFinishSettings: (value, multiplier = 1.0) ->
        if value < 0
            return 0
        a = @_balconomy.economy.immediateFinishSettings.powerFunctionParamA
        b = @_balconomy.economy.immediateFinishSettings.powerFunctionParamB
        c = @_balconomy.economy.immediateFinishSettings.powerFunctionParamC
    
        result = Math.pow( (a * value + c), b ) * multiplier
        return mathCSharp.roundNumber(result) # ROUND TO INT IN CLIENT MAY BE PROBLEMATIC!

    calculateRankLevelsSettings: (value) ->
        if(value > 21)
            return Number.MAX_SAFE_INTEGER

        a = @_balconomy.economy.rankLevelsSettings.powerFunctionParamA
        b = @_balconomy.economy.rankLevelsSettings.powerFunctionParamB
        c = @_balconomy.economy.rankLevelsSettings.powerFunctionParamC

        result = mathCSharp.roundNumber(Math.pow( (a * value + c), b))
        return mathCSharp.roundNumber(result / 20) * 20

    getRankLevel: (trophies) ->
        RANK_MAX = 21
        index = 2

        while(index > 0)
            calculatedValue = @calculateRankLevelsSettings(index)
            if(trophies < calculatedValue)
                return index - 1

            index++

        return RANK_MAX

    getThroneResourceLimit: (throneLevel) ->
        for limit in @_balconomy.balance.throneResource
            if(limit.level == throneLevel)
                return limit

        console.log '[WARNING] couldnt find throne resource limit for level '+throneLevel

    getAdsLimit: () ->
        return @_balconomy.economy.adsSettings.adsCountLimit

    getAdsReduceProductionTimePercent: () ->
        return @_balconomy.economy.adsSettings.adsReduceProductionTimePercent
        
    getAdsHoursToResetLimit: () ->
        return @_balconomy.economy.adsSettings.adsHoursToResetLimit

    getFreeGemsAdsCountLimit: () ->
        return @_balconomy.economy.adsSettings.freeGemsAdsCountLimit

    getFreeGemsAdsReward: () ->
        return @_balconomy.economy.adsSettings.freeGemsAdsReward

    getFreeGemsAdsHoursToResetLimit: () ->
        return @_balconomy.economy.adsSettings.freeGemsAdsHoursToResetLimit

    getFindNewPlayerCost: () ->
        return @_balconomy.economy.playerSearchCost

    getFullTimeOfBattle: () ->
        return @_balconomy.config.battleData.TimeBattle * 1000 + @_balconomy.config.battleData.TimeBeforeBattle * 1000

    getFightHistoryLimit: () ->
        return @_balconomy.config.fightHistoryLimit

    getBuilderCost: (builderCount) ->
        for builderCost in @_balconomy.economy.builderCosts
            if builderCost.buildersCount == builderCount
                return builderCost.nextBuilderGemsCost

        console.log 'Builders cost not found'
        return 0

    resolveUpgradeAchivementId: (roomType) ->
        switch roomType
            when "TREASURY_VAULT" then return "achivMakeIt"
            when "THRONE" then return "achivFortress"
            when "EXPLORER" then return "achivBroaden"
            when "ARMORY" then return "achivFirepower"
            else return "none"

    resolveDestroyAchivementId: (roomType) ->
        if @isFortificationRoom(roomType)
            return "achivWall"

        switch roomType
            when "THRONE" then return "achivRemember"
            when "BUILDER" then return "achivManpower"
            when "ARCHER" then return "achivSkies"
            when "SHOOTING_LASER_RAY" then return "achivLaser"
            when "SHOOTING_ANTI_ALTILERY" then return "achivShells"
            else return "none"

    getAchievement: (achievementId) ->
        for achievement in @_balconomy.achievement
            if achievementId == achievement.id
                return achievement;

        console.log '[ERROR] Cannot find achievement ' + achievementId
        return null

    getLeaugeRewards: (leagueLevel) ->
        for reward in @_balconomy.economy.leagueRewards
            if reward.leagueLevel == leagueLevel
                return reward

        console.log '[ERROR] Cannot find leaugeRewards level: ' + leagueLevel
        return null

    getResourceStealingRatesMultiplier: (throneLevel) ->
        for multiplier in @_balconomy.economy.resourceStealingRatesMultiplier
            if multiplier.level == throneLevel
                return multiplier
        
        console.log '[ERROR] Cannot find resourceStealingRatesMultiplier level: ' + throneLevel
        return null

    getProjectileProductionHardCostMultiplier: () ->
        #console.log "getProjectileProductionHardCostMultiplier: " + @_balconomy.economy.projectileProductionHardCostMultiplier
        if (!@_balconomy.economy.projectileProductionHardCostMultiplier?)
            console.log "[ERROR] getProjectileProductionHardCostMultiplier undefined"
            return 1
        return @_balconomy.economy.projectileProductionHardCostMultiplier

    getAttackCost: (throneLevel) ->
        for attackCost in @_balconomy.economy.attackCosts
            if attackCost.throneRoomLevel == throneLevel
                return attackCost
        
        console.log '[ERROR] Cannot find attackCosts level: ' + throneLevel
        return null

    getScoutTime: () ->
        return @_balconomy.config.scoutTime

    getSlotAssociation: () ->
        return @_balconomy.balance.slotAssociation

    getBossLocations: () ->
        locations = [];
        for loc in @_balconomy.balance.bossLocations
            locations.push(loc.bossSlotId)

        return locations

    getRoomAllParams: (roomType) ->
        id = @resolveRoomId roomType
        for room in @_balconomy.balance.roomParams
            if room.id == id
                return room.levels

        util.log '[ERROR] Couldnt find room params for roomType ' + roomType + ' level ' + level
                        
        return null

module.exports = Balconomy