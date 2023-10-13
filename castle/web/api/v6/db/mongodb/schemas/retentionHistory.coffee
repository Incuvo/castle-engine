mongoose = require 'mongoose'
Schema = mongoose.Schema
util = require 'util'
mm = require('../models')
versionModule = require '../../../routes/version'
version = versionModule.api.version

module.exports = retentionHistory = new Schema
    user: {type: Schema.ObjectId, ref: "UserProfile_#{version}"}
    game: {
        number: {type: Number, default: 0}
        start: {type: Number, default: 0}
        end: {type: Number, default: 0}
    }

retentionHistory.methods.getGamesCount = () ->
    obj = @
    mm.RetentionHistory.find({"user":obj.user}).count() (err, total) ->
        if err
            util.log '[ERROR] Error counting games ' + err + ' at getGamesCount'
            return null
        return total

retentionHistory.methods.closeGame = (timestamp, cb) ->
    obj = @
    if obj.game.end == null
        # game is open
        obj.game.end = timestamp
    else
        # game was closed sometime!
        return cb null
        
    obj.save (err, retentionHistory) ->
        if err?
            util.log '[ERROR] Error saving retentionHistory ' + err + ' at closeGame'
            return cb err
        #console.log '[retentionHistory] games array updated with ' + retentionHistory.getGamesCount() + 'number.'
#        console.log '[retentionHistory] game nr ' + retentionHistory.game.number + ' closed for user: ' + retentionHistory.user
        return cb null



