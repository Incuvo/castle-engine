mongoose = require 'mongoose'
ObjectId = mongoose.Types.ObjectId

exports.ConvertToIdsArray = (idsArray) ->
    objectIdArray = []
    for id in idsArray
        objectIdArray.push(new ObjectId(id.toString()))

    return objectIdArray

exports.ConvertIdsToArray = (ids) ->
    objectIdArray = []
    for id in ids
        objectIdArray.push(id._id)

    return objectIdArray