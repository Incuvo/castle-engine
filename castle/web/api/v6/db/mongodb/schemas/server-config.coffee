mongoose = require 'mongoose'


Schema = mongoose.Schema

module.exports = ServerConfig = new Schema
    operation_mode : {type: String, default: 'rw'}

    counters:
        promo_code : {type: Number, default: 0}

    created : {type: Boolean, default: true}

    operation_mode : {type: Boolean, default: true}

    time_to_end : {type: Number, default: 0}

    promo_date : {type: Number, default: Date.now() - 10000}