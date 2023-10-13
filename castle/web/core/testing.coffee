# Defines helper functions for functional tests.

async = require 'async'
mm = require '././mongodb/models'


#createUser = (email, username, password, roles, cb) ->
#    mm.User.create {
#        email: email
#        username: username
#        password: password
#        roles: roles
#    }, (err, user) ->
#        if err?
#            return cb err
#
#        mm.AppAuthorization.create {user: user._id}, (err, appAuth) ->
#            return cb err, user, appAuth


createLevel = (owner, original, name, description, gameplay, visibility, tags, flags, cb) ->
    mm.Level.create {
        owner: owner
        original: original
        name: name
        description: description
        gameplay: gameplay
        visibility: visibility
        tags: tags
        flags: flags
    }, (err, level) ->
        return cb err, level


# Creates multiple users (in parallel).
exports.createUsers = (users, cb) ->
    users_ = {$all: []}

    funcs = []

    for u in users
        funcs.push ((u) ->
            return (cb) ->
                createUser u[0], u[1], u[2], u[3], (err, user, appAuth) ->
                    if err?
                        return cb err, null

                    users_[user.username] =
                        doc: user
                        auth: appAuth
                        headers: {'X-Castle-Auth': appAuth.access_token}

                    users_.$all.push user._id

                    return cb err, user._id
        )(u)

    async.parallel funcs, (err, results) ->
        return cb err, users_


# Removes users with given IDs.
#
# `users`: an array of IDs
exports.removeUsers = (users, cb) ->
    mm.User.where('_id').in(users).remove (err, count) ->
        return cb err, count


# Creates multiple levels (in parallel).
exports.createLevels = (levels, cb) ->
    levels_ = {$all: []}

    funcs = []

    for l in levels
        funcs.push ((l) ->
            return (cb) ->
                createLevel l[0], l[1], l[2], l[3], l[4], l[5], l[6], l[7], (err, level) ->
                    if err?
                        return cb err, null

                    ownerStr = "#{level.owner}"

                    if ownerStr not of levels_
                        levels_[ownerStr] =
                            $private: []
                            $public: []

                    levelData =
                        doc: level

                    levels_.$all.push level._id

                    levels_[ownerStr]["#{level._id}"] = levelData

                    if level.visibility == 'public'
                        levels_[ownerStr].$public.push levelData

                    if level.visibility == 'private'
                        levels_[ownerStr].$private.push levelData

                    return cb err, level._id
        )(l)

    async.parallel funcs, (err, results) ->
        return cb err, levels_


# Removes levels with given IDs.
exports.removeLevels = (levels, cb) ->
    mm.Level.where('_id').in(levels).remove (err, count) ->
        return cb err, count
