mongoose = require 'mongoose'


Schema = mongoose.Schema

module.exports = FailedAuth = new Schema
    username: {type: String}
    ip: {type: String, default: ''}
    created: {type: Number, default: Date.now}
