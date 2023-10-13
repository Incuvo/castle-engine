mongoose = require 'mongoose'
Schema = mongoose.Schema

mm = require('../models')
mv = require('./../../../model-views')
util = require 'util'
versionModule = require '../../../routes/version'
version = versionModule.api.version

module.exports = League = new Schema
    ownerId: {type: Schema.ObjectId, ref: "UserProfile_#{version}"}
    leagueLevel: {type: Number, default: 0}
    members: [{type: Schema.ObjectId, ref: "UserProfile_#{version}"}]

League.statics.createLeague = (owner, leagueLevel, balconomy, cb) ->
    minTrophies = balconomy.calculateRankLevelsSettings(leagueLevel)
    maxTrophies = balconomy.calculateRankLevelsSettings(leagueLevel + 1)

    mm.UserProfile.aggregate([{"$match": {$and: [{"trophies":{$gte: minTrophies, $lt: maxTrophies}}, {"_id": {$ne: owner._id}}, {"display_name": {$ne: ''}}, {profileType: 'PLAYER'}]}}, {"$project" :{"_id": 1}}, { $sample : {size: 200}}, { $sort: {"trophies":-1}}]).exec (err, users) ->
        if(err?)
            return cb err, null

        mm.League.create {
            ownerId: owner._id
            leagueLevel: leagueLevel
            members: users
        }, (err, league) ->
            if(err?)
                return cb err, null

            return cb null, league

League.methods.getLeagueList = (user, balconomy, cb) ->
    doc = @
    minTrophies = balconomy.calculateRankLevelsSettings(doc.leagueLevel)
    maxTrophies = balconomy.calculateRankLevelsSettings(doc.leagueLevel + 1)    

    mm.UserProfile.find({"_id": {$in: doc.members}, "trophies":{$gte: minTrophies, $lt: maxTrophies}}).select('stats trophies display_name').sort({_id: -1}).limit(99).exec (err, users) ->
        if(err?)
            return cb err, null

        if(users.length >= 99)

            users.push(user)

            users.sort (a, b) ->
                return b.trophies - a.trophies


            view = new mv.Leaderboard(users)
            view.export (err, leaderboardView) ->
                if(err?)
                    return cb err, null

                return cb null, leaderboardView

        else
            doc.addNewMembers balconomy, (err, updatedLeague) ->
                if(err?)
                    return cb err, null

                doc = updatedLeague
                mm.UserProfile.find({"_id": {$in: doc.members}, "trophies":{$gte: minTrophies, $lt: maxTrophies}}).select('stats trophies display_name').exec (err, users) ->
                    if(err?)
                        return cb err, null

                    users.push(user)

                    users.sort (a, b) ->
                        return b.trophies - a.trophies

                    view = new mv.Leaderboard(users)
                    view.export (err, leaderboardView) ->
                        if(err?)
                            return cb err, null

                        return cb null, leaderboardView

League.methods.addNewMembers = (balconomy, cb) ->
    doc = @
    minTrophies = balconomy.calculateRankLevelsSettings(doc.leagueLevel)
    maxTrophies = balconomy.calculateRankLevelsSettings(doc.leagueLevel + 1)

    mm.UserProfile.aggregate([{"$match": {$and:[{"trophies":{$gte: minTrophies, $lt: maxTrophies}}, {"_id": {$nin: doc.members}}, {"_id": {$ne: doc.ownerId}}, {"display_name": {$ne: ''}}]}}, {"$project" :{"_id": 1}}, { $sample : {size: 100}}, { $sort: {"trophies":-1}}]).exec (err, users) ->
        if(err?)
            return cb err, null

        doc.members = doc.members.concat(users)
        doc.save (err, obj) ->
            if err?
                util.log '[ERROR] Saving league ' + err
                return cb err, null

            return cb null, obj

League.methods.updateLeagueLevel = (newLevelLeague, balconomy, cb) ->
    doc = @
    doc.leagueLevel = newLevelLeague

    minTrophies = balconomy.calculateRankLevelsSettings(doc.leagueLevel)
    maxTrophies = balconomy.calculateRankLevelsSettings(doc.leagueLevel + 1)

    mm.UserProfile.aggregate([{"$match": {$and: [{"trophies":{$gte: minTrophies, $lt: maxTrophies}}, {"_id": {$ne: doc.ownerId}}, {"display_name": {$ne: ''}}]}}, {"$project" :{"_id": 1}}, { $sample : {size: 200}}, { $sort: {"trophies":-1}}]).exec (err, users) ->
        if(err?)
            return cb err, null

        doc.members = users
        doc.save (err, obj) ->
            if err?
                util.log '[ERROR] Saving league ' + err
                return cb err, null

            return cb null, obj