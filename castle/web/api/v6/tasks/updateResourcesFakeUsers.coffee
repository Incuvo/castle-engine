u       = require 'underscore'
async   = require 'async'
mm      = require '../db/mongodb/models'
mw      = require '../middleware'
ex      = require '../../exceptions'
mv      = require '../model-views'
moment   = require 'moment'
util    = require 'util'

exports = module.exports = (scheduler, lock, app) ->

    rule = new scheduler.RecurrenceRule(null, null, null, null, null, null, 1)

    job = scheduler.scheduleJob rule, () ->
        findQuery = {fakeAccount: true, 'castle.resourcesList.quantity': {$lt: 997}}
        lock (release) ->
            mm.UserProfile.find findQuery, (err, users) ->
                async.each users, (user, cb) ->
                    for resource, index in user.castle.resourcesList
                        if resource.quantity < 997
                            user.castle.resourcesList[index].quantity = resource.quantity + 4
                    user.save (err) ->
                        if err?
                            util.log '[ERROR] in saving doc ' + err.toString()
                release()
    return job

