mongoose = require 'mongoose'
u = require 'underscore'
util = require 'util'

Schema = mongoose.Schema

module.exports = Persistent = new Schema {}, {strict: false}