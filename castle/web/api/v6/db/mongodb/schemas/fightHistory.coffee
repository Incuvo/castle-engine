mongoose = require 'mongoose'
Schema = mongoose.Schema

mm = require('../models')
mv = require '../../../model-views'
onesignal = require '../../../onesignal'
ts = require '../../../../../util/time'
util = require 'util'
versionModule = require '../../../routes/version'
version = versionModule.api.version
GameInn = require './../../../../../../../GameInn/index.js'

module.exports = fightHistory = new Schema
    attacker: {type: Schema.ObjectId, ref: "UserProfile_#{version}"}
    defender: {type: Schema.ObjectId, ref: "UserProfile_#{version}"}
    timestamp: {type: Number, default: 0}
    ammoList: [{
        projectileId: {type: String, default: ''}
        projectileLevel: {type: Number, default: 0}
        projectileAmount: {type: Number, default: 0}
    }]
    attackerTrophies: {type: Number, default: 0}
    defenderTrophies: {type: Number, default: 0}
    attackerEarn: {type: Number, default: 0}
    defenderEarn: {type: Number, default: 0}
    stars: {type: Number, default: 0}
    percent: {type: Number, default: 0}
    replay: {type: Schema.ObjectId, ref: "Replay_#{version}"}
    revenge: {type: Boolean, default: false}
    isBattleEnd: {type: Boolean, default: false}
    resourcesList: [{
        quantity: {type: Number, default: 0}
        quantityWithoutCollectors: {type: Number, default: 0}
        resourceType: {type: String, default: ''}
    }]
    resourcesToSteal: [{
        quantity: {type: Number, default: 0}
        resourceType: {type: String, default: ''}
    }]
    resourcesCollectorsList: [{
        resourcesQuantity: {type: Number, default: 0}
        roomId: {type: String, default: ''}
    }]
    destroyedRoomsList: [type: String]
    tutorialBattle: {type: Boolean, default: false}
    forfeit: {type: Boolean, default: true}

fightHistory.statics.getTutorialBattleState = (userId, cb) ->
    mm.FightHistory.find {attacker: userId, tutorialBattle: true}, (err, tutorialFights) ->
        if err
            return cb err, null

        for tf in tutorialFights
            if tf.stars > 0
                return cb null, true

        return cb null, false

fightHistory.methods.endBattle = (balconomy, cb) ->
    obj = @

    mm.UserProfile.findById obj.attacker, (err, attackerUser) ->
        if err
            return cb err

        mm.UserProfile.findById obj.defender, (err, defenderUser) ->
            if err
                return cb err

            if not defenderUser
                util.log '[ERROR] defender not found: ' + obj.defender
            
            EarnTrophies = attackerUser.getTrophiesEarn defenderUser

            if obj.stars > 0
                # battle won

                goldLimit = attackerUser.getGoldLimit(balconomy)
                manaLimit = attackerUser.getManaLimit(balconomy)

                for room in defenderUser.castle.roomsList
                    for collectorSteal in obj.resourcesCollectorsList
                        if room.name == collectorSteal.roomId
                            if room.roomType == "TAX_COLLECTOR" or room.roomType == "ALCHEMICAL_WORKSHOP"
                                roomQuantity = mv.UserProfile.calculateResourceInRoom room, balconomy, obj.timestamp
                                room.resourceProdQuantity = roomQuantity - collectorSteal.resourcesQuantity
                                if (obj.timestamp / 1000) > (ts.clientTimeformatToTimestamp(room.lastCollectTime) / 1000)
                                    room.lastCollectTime = ts.timestampToClientTimeformat obj.timestamp

                                if (room.resourceProdQuantity < 0)
                                    util.log '[WARN] room resource prod quantity shouldnt be less than zero - ' + defenderUser._id   #+ JSON.stringify defenderUser.toObject()
                                    room.resourceProdQuantity = Math.max room.resourceProdQuantity, 0

                for playerResource in defenderUser.castle.resourcesList
                    for resourcesSteal in obj.resourcesList
                        if playerResource.resourceType == resourcesSteal.resourceType
                            playerResource.quantity -= resourcesSteal.quantityWithoutCollectors
                            playerResource.quantity = Math.max playerResource.quantity, 0
                            
                for playerResource in attackerUser.castle.resourcesList
                    for resourcesSteal in obj.resourcesList
                        if playerResource.resourceType == resourcesSteal.resourceType
                            playerResource.quantity += resourcesSteal.quantity

                            if playerResource.resourceType == "GOLD"
                                attackerUser.incrementAchievementProgress 'achivGoldJaunt', resourcesSteal.quantity
                                playerResource.quantity = Math.min playerResource.quantity, goldLimit
                            else if playerResource.resourceType == "MANA"
                                attackerUser.incrementAchievementProgress 'achivElixirRaid', resourcesSteal.quantity
                                playerResource.quantity = Math.min playerResource.quantity, manaLimit

                leagueLevel = balconomy.getRankLevel(attackerUser.trophies + EarnTrophies + obj.stars)
                rewardResources = balconomy.getLeaugeRewards(leagueLevel)

                if(rewardResources?)
                    for playerResource in attackerUser.castle.resourcesList
                        if playerResource.resourceType == "GOLD"
                            playerResource.quantity += rewardResources.leagueResourceReward
                            playerResource.quantity = Math.min playerResource.quantity, goldLimit
                        else if playerResource.resourceType == "MANA"
                            playerResource.quantity += rewardResources.leagueResourceReward
                            playerResource.quantity = Math.min playerResource.quantity, manaLimit

                attackerUser.stats.attacksWon = attackerUser.stats.attacksWon + 1
                defenderUser.stats.defencesLost = defenderUser.stats.defencesLost + 1
                attackerUser.stats.winsStreak = attackerUser.stats.winsStreak + 1
                if attackerUser.stats.winsStreak > attackerUser.stats.bestWinsStreak
                    attackerUser.stats.bestWinsStreak += 1
                attackerUser.stats.losesStreak = 0
                earnTrophiesAttacker = parseInt(EarnTrophies + obj.stars)
                earnTrophiesDefender = -earnTrophiesAttacker

                if obj.stars == 3
                    attackerUser.stats.threeStarsWins += 1
                    attackerUser.setAchievementProgress 'achivEffort', attackerUser.stats.threeStarsWins
                #EarnTrophies = parseInt(Math.round(EarnTrophies / 3) * obj.stars)
                onesignal.simpleUserNotification "Castle has been attacked!", defenderUser._id
                for slot, index in attackerUser.map
                    #QUICKFIX ZWAŁY SERWA
                    if slot != null and slot.user != null and defenderUser != null and defenderUser._id != null
                        if slot.user.toString() == defenderUser._id.toString()
                            attackerUser.map[index].defeated = true
                            break
                    else
                        util.log '[ERROR] Error on map index ' + index + ' for ' + attackerUser._id

                if defenderUser.profileType == 'NPC_BOSS'
                    attackerUser.incrementAchievementProgress 'achivGraysons', 1
                    attackerUser.stats.bossesDefeated += 1

                defeatedCastles = attackerUser.getDefeatedCastles()
                attackerUser.setAchievementProgress 'achivEndless', defeatedCastles


            else
                obj.resourcesList = []
                obj.resourcesCollectorsList = []

                attackerUser.stats.attacksLost = attackerUser.stats.attacksLost + 1
                defenderUser.stats.defencesWon = defenderUser.stats.defencesWon + 1
                defenderUser.setAchievementProgress 'achivHome', defenderUser.stats.defencesWon
                attackerUser.stats.winsStreak = 0
                attackerUser.stats.losesStreak = attackerUser.stats.losesStreak + 1
                # trophies go to defender
                earnTrophiesAttacker = 0
                earnTrophiesDefender = EarnTrophies
                onesignal.simpleUserNotification "Castle has been attacked!", defenderUser._id

            #obj.attackerEarn = EarnTrophies
            #obj.defenderEarn = -EarnTrophies
            # FightHistory statistics
            obj.attackerEarn = earnTrophiesAttacker
            obj.defenderEarn = earnTrophiesDefender

            attackerUser.trophies += earnTrophiesAttacker
            attackerUser.setAchievementProgress 'achivEnemy', attackerUser.trophies
            attackerUser.setAchievementProgress 'achivLeague', attackerUser.trophies

            for roomType in obj.destroyedRoomsList
                achievementId = balconomy.resolveDestroyAchivementId(roomType)
                if achievementId != 'none'
                    attackerUser.incrementAchievementProgress achievementId, 1
            #attackerUser.trophies = Math.max attackerUser.trophies, 0

            #STATISTICS
            
            attackerUser.activeBattle = undefined
            obj.isBattleEnd = true
            obj.save (err, fightHistory) ->
                if err?
                    return cb err

                GameInn.SendEvent 'BATTLE_END', {fightHistoryID: fightHistory._id, attackerID: attackerUser._id, defenderID: defenderUser._id, attackerThrone: attackerUser.getThroneLevel(), defenderThrone: defenderUser.getThroneLevel(), isAttackerWin: fightHistory.stars > 0}, (err, data) ->
                    if err?
                        console.log err

                attackerUser.save (err, attackerUser) ->
                    if err?
                        return cb err
                    if defenderUser.profileType != 'PLAYER'
                        return cb null
                    else
                        defenderUser.trophies += earnTrophiesDefender
                        defenderUser.trophies = Math.max defenderUser.trophies, 0
                        defenderUser.activeBattle = undefined
                        # STATISTICS
                        defenderUser.save (err, defenderUser) ->
                            if err?
                                return cb err

                            return cb null

