mongoose = require 'mongoose'
util = require 'util'

Schema = mongoose.Schema

module.exports = Balconomy = new Schema
    name   : {type: String, default: ''}
    version: {type: String, default: ''}
    config :
        costCategories: [{
            id: {type: String, default: ''}
            name: {type: String, default: ''}
        }]
        roomsCategories: [{
            id: {type: String, default: ''}
            name: {type: String, default: ''}
        }]
        projectilesCategories: [{
            id: {type: String, default: ''}
            name: {type: String, default: ''}
        }]
        roomsDefinitions: [{
            id: {type: String, default: ''}
            roomCategoryId: {type: String, default: ''}
            name: {type: String, default: ''}
            buyCostCategoryId: {type: String, default: ''}
            upgradeCostCategoryId: {type: String, default: ''}
            descriptionId: {type: String, default: ''}
        }]
        projectilesDefinitions: [{
            id: {type: String, default: ''}
            projectileCategoryId: {type: String, default: ''}
            name: {type: String, default: ''}
            costCategoryId: {type: String, default: ''}
            descriptionId: {type: String, default: ''}
            armoryLevelRequirement: {type: Number, default: 0}
            projectileOrder: {type: Number, default: 0}
            damageType: {type: String, default: ''}
            goodAgainst: {type: String, default: ''}
        }]
        battleData:
            TimeBattle: {type: Number, default: 180}
            TimeBeforeBattle: {type: Number, default: 30}
        showSupportButton: {type: Boolean, default: false}
        replayTimeToLive: {type: Number, default: 1209600000}
        fightHistoryLimit: {type: Number, default: 30}
        scoutTime: {type: Number, default: 30}
        maxRateUsRequests: {type: Number, default: 0}
    economy:
        immediateFinishSettings:
            powerFunctionParamA: {type: Number, default: 0.75}
            powerFunctionParamB: {type: Number, default: 0.75}
            powerFunctionParamC: {type: Number, default: 0}
        exchangeGemsRateSettings:
            powerFunctionParamA: {type: Number, default: 0.005}
            powerFunctionParamB: {type: Number, default: 0.75}
            powerFunctionParamC: {type: Number, default: 0}
        cloudPricesCurveDesc:
            powerFunctionParamA: {type: Number, default: 1.15}
            powerFunctionParamB: {type: Number, default: 3.0}
            powerFunctionParamC: {type: Number, default: 8.0}
        rankLevelsSettings:
            powerFunctionParamA: {type: Number, default: 1.881}
            powerFunctionParamB: {type: Number, default: 2.1}
            powerFunctionParamC: {type: Number, default: 0.0}
        gemsInApps:
            inAppCategoryType: {type: String, default: ''}
            inApps: [{
                UID: {type: String, default: ''}
                InAppID: {type: String, default: ''}
                Desc: {type: String, default: ''}
                Icon: {type: String, default: ''}
                Name: {type: String, default: ''}
                Value: {type: String, default: ''}
            }]
        bundleInApps: {
            inAppCategoryType: {type: String, default: "PBD_BUNDLE"}
            inApps: [{
                UID: {type: String, default: ''}
                InAppID: {type: String, default: ''}
                Desc: {type: String, default: ''}
                Icon: {type: String, default: ''}
                Name: {type: String, default: ''}
                Value: {type: String, default: ''}
            }]
        }
        resourceStealingRates:
            thronesRoomStealingRate: {type: Number, default: 0.3}
            storageRoomStealingRate: {type: Number, default: 0.3}
            productionRoomStealingRate: {type: Number, default: 0.3}
        playerSearchCost: {type: Number, default: 0}
        adsSettings:
            adsCountLimit: {type: Number, default: 0}
            adsReduceProductionTimePercent: {type: Number, default: 0}
            adsHoursToResetLimit: {type: Number, default: 0}
            freeGemsAdsCountLimit: {type: Number, default: 0}
            freeGemsAdsReward: {type: Number, default: 0}
            freeGemsAdsHoursToResetLimit: {type: Number, default: 0}
        builderCosts: [{
            buildersCount: {type: Number, default: 0}
            nextBuilderGemsCost: {type: Number, default: 0}
        }]
        leagueRewards: [{
            leagueLevel: {type: Number, default: 0}
            leagueResourceReward: {type: Number, default: 0}
        }]
        resourceStealingRatesMultiplier: [{
            level: {type: Number, default: 0}
            multiplier: {type: Number, default: 0}
        }]
        projectileProductionHardCostMultiplier: {type: Number, default: 1}
        attackCosts: [{
            throneRoomLevel: {type: Number, default: 0}
            randomAttackCost: {type: Number, default: 0}
        }]
    balance:
        roomParams: [{
            id: {type: String, default: ''}
            roomLevels: [{
                level: {type: Number, default: 0}
                costValue: {type: Number, default: 0}
                constructionTime: {type: Number, default: 0}
                hitpoints: {type: Number, default: 0}
                damageValue: {type: Number, default: 0}
                effectRange: {type: Number, default: 0}
                capacity: {type: Number, default: 0}
                productionRate: {type: Number, default: 0}
                boostCost: {type: Number, default: 0}
            }]
        }]
        projectileParams: [{
            id: {type: String, default: ''}
            category: {type: String, default: ''}
            projectileLevels: [{
                level: {type: Number, default: 0}
                costValue: {type: Number, default: 0}
                constructionTime: {type: Number, default: 0}
                researchCost: {type: Number, default: 0}
                researchTime: {type: Number, default: 0}
                laboratoryLevel: {type: Number, default: 0}
                storageSpace: {type: Number, default: 0}
                damageRange: {type: Number, default: 0}
                damageValue: {type: Number, default: 0}
                damageMultiplier: {type: Number, default: 0}
                cooldownTime: {type: Number, default: 0}
                healthPoints: {type: Number, default: 0}
                speed: {type: Number, default: 0}
            }]
        }]
        roomLimits: [{
            roomTypeId: {type: String, default: ''}
            throneLevelList: [{
                hearthLevel: {type: Number, default: 0}
                roomLimit: {type: Number, default: 0}
                maxRoomLevel: {type: Number, default: 0}
            }]
        }]
        catapultParams: [{
            upgradeType: {type: String, default: ''}
            costCategory: {type: String, default: ''}
            CatapultLevels: [{
                level: {type: Number, default: 0}
                costValue: {type: Number, default: 0}
                buildTime: {type: Number, default: 0}
                WorkshopLevelNeeded: {type: Number, default: 0}
                Value: {type: Number, default: 0}
            }]
        }]
        throneResource: [{
            level: {type: Number, default: 0}
            GOLD: {type: Number, default: 0}
            MANA: {type: Number, default: 0}
            DARK_MANA: {type: Number, default: 0}
        }]
        radarRanges: [{
            level: {type: Number, default: 0}
            cloudRange: {type: Number, default: 0}
            slotRange: {type: Number, default: 0}
            refillCap: {type: Number, default: 0}
        }]
        slotAssociation: [Number]
        lootCart: {
            lootCartTimeToFill: {type: Number, default: 0}
            timeToShowLootCart: {type: Number, default: 0}
            tentGoldProductionRate: {type: Number, default: 0}
            tentManaProductionRate: {type: Number, default: 0}
        }
    achievement: [{
        id: {type: String}
        name: {type: String}
        description: {type: String}
        step: [type: Number]
        reward: [type: Number]
    }]

Balconomy.statics.getLastVersion = (cb) ->
    @.find().sort({version : -1}).limit(1).exec (err, doc) ->
        if err?
            util.log '[ERROR] ' + err + ' in getting last balconomy'
        else if doc.length == 0
            util.log '[ERROR] NO BALCONOMY IN MONGO !'
        else
            doc = doc[0].toObject()
            cb(doc)