mongoose = require 'mongoose'
Schema = mongoose.Schema
versionModule = require '../../../routes/version'
version = versionModule.api.version

module.exports = Purchase = new Schema
    user   : {type: Schema.ObjectId, ref: "UserProfile_#{version}"}
    receipt: Schema.Types.Mixed
    reason: {type: String, default: ''}
    purchaseStatus: {type: String, default: 'COMPLETED'}
    plat   : {type: String, default: ''}
    created: {type: Date, default: Date.now}
