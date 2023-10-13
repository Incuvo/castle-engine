mongoose = require 'mongoose'
Schema = mongoose.Schema
versionModule = require '../../../routes/version'
version = versionModule.api.version

module.exports = Replay = new Schema
    fightHistoryId: {type: Schema.ObjectId, ref: "UserProfile_#{version}"}
    replay: {type: Buffer }