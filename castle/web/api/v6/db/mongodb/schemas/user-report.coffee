mongoose = require 'mongoose'
Schema = mongoose.Schema
versionModule = require '../../../routes/version'
version = versionModule.api.version

module.exports = UserReport = new Schema
    owner               : { type: Schema.ObjectId, ref: "User_#{version}"}
    owner_username      : { type: String, default: '' }
    type                : [{type: String, lowercase: true}]
    reason              : { type: String, default: '' }
    created             : { type: Number, default: Date.now}
    subject_type        : { type: String, default: '' }
    subject_id          : { type: Schema.ObjectId }
    subject_content     : { type: String, default: '' }
    subject_owner_id    : { type: Schema.ObjectId}
    status              : { type: String, default: 'NEW' }
