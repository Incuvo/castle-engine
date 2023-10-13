# Defines OAuth-related route handlers.

mongoose = require 'mongoose'
fbgraph  = require 'fbgraph'
bcrypt   = require 'bcrypt'
hashids  = require 'hashids'
moment   = require 'moment'
api      = require './api'
util     = require 'util'

mm = require '../db/mongodb/models'
ex = require '../../exceptions'
mv = require '../model-views'

GameInn = require './../../../../../GameInn/index.js'


# Supported grant types
GRANT_TYPES = ['password']

exports.oauth = (req, res, next) ->
    
    if not (req.body.grant_type in GRANT_TYPES)
        throw new ex.InvalidGrantType GRANT_TYPES

    plat = req.headers['x-plat'] || 'any'
    lang = req.headers['lang'] || 'en'
    device_token = req.body.device_token || ''

    ip_address = req.headers['x-forwarded-for'] || req.connection.remoteAddress

    isReadOnlyMode = req.app.castle.config.server.operationMode == 'r'

    if req.body.email?
        property = {name: 'email', value: req.body.email}
    else if req.body.username?
        property = {name: 'username', value: req.body.username}
    else
        return next new ex.MissingParameters ['email', 'username']

    #prevent check for brute forse login method (after three times of wrong auth, user will be locked for 5 min )
    mm.FailedAuth.find( { username : req.body.username, created: { '$gt' : Date.now() - (1000 * 60 * 5) }} ).count (err, failedAuthCount) ->

        if err?
            return next err

        if failedAuthCount > 2
            return next new ex.AuthFailedTooManyAttempts


        if req.body.grant_type == 'password'

                
            # Authenticates user based on login/password credentials.
            mm.UserProfile.authenticate(
                property,
                req.body.password,
                req.app.castle.balconomy
                (user) ->

                    if "deleted" in user.flags
                        return next new ex.AuthFailed('ban')

                    if user.ban_expiration and user.ban_expiration > Date.now()
                        return next new ex.AuthFailed('ban')

                    if user.access_token
                        # Resets access token, if exists
                        if isReadOnlyMode

                            GameInn.SendEvent 'USER_LOGIN', {userID: user._id}, (err, data) ->
                                if err?
                                    console.log err

                            view = new mv.UserProfile(user, {balconomy: req.app.castle.balconomy, user: user})
                            res.json
                                access_token: user.access_token
                                user: view.export()
                                access_created : user.info.access_created

                            return

                        lastTokenDate = moment user.info.access_created

                        user.resetToken(req)
                        user.info.device_token = device_token
                        user.info.lang = lang
                        user.info.plat = plat

                        currentTokenDate = moment user.info.access_created

                        lastTokenDate.hour(0)
                        lastTokenDate.minute(0)
                        lastTokenDate.second(0)
                        lastTokenDate.milliseconds(0)

                        currentTokenDate.hour(0)
                        currentTokenDate.minute(0)
                        currentTokenDate.second(0)
                        currentTokenDate.milliseconds(0)

                        balconomy = req.app.castle.balconomy

                        if(user.lastScoutTimestamp?)
                            if(user.lastScoutTimestamp + balconomy.getScoutTime() * 1000 + 30000 > Date.now())
                                return next new ex.BattleOnline

                        user.isBattleOnline balconomy, (err, online) ->
                            if err?
                                return next err

                            if online
                                mm.FightHistory.findById user.activeBattle, (err, fightHistory) ->
                                    if fightHistory.attacker.toString() == user._id.toString()
                                        fightHistory.endBattle balconomy, (err) ->
                                            if err?
                                                return next err

                                            mm.UserProfile.findOneAndUpdate({_id: user._id}, {access_token: user.access_token, info: user.info, resetRequired: false, last_user_activity: Date.now()}, {new:true}).populate('map.user').exec (err, updatedUser) ->
                                                if err
                                                    return next err

                                                GameInn.SendEvent 'USER_LOGIN', {userID: user._id}, (err, data) ->
                                                    if err?
                                                        console.log err

                                                view = new mv.UserProfile(updatedUser, {balconomy: balconomy, user: user})
                                                view.export (err, obj) ->

                                                    res.json
                                                        access_token: user.access_token
                                                        user: obj
                                                        last_access_token_days_delta : currentTokenDate.diff lastTokenDate, 'days'
                                                        access_created : user.info.access_created
                                                        balconomy: balconomy.get()
                                                        ts: Date.now()

                                    else if fightHistory.defender.toString() == user._id.toString()
                                        return next new ex.BattleOnline

                            else
                                mm.UserProfile.update {_id: user._id}, {access_token: user.access_token, info: user.info, resetRequired: false, last_user_activity: Date.now()}, (err, updated) ->
                                    if err
                                        return next err

                                    GameInn.SendEvent 'USER_LOGIN', {userID: user._id}, (err, data) ->
                                        if err?
                                            console.log err

                                    view = new mv.UserProfile(user, {balconomy: balconomy, user: user})
                                    view.export (err, obj) ->

                                        res.json
                                            access_token: user.access_token
                                            user: obj
                                            last_access_token_days_delta : currentTokenDate.diff lastTokenDate, 'days'
                                            access_created : user.info.access_created
                                            balconomy: balconomy.get()
                                            ts: Date.now()


                    else
                        # Generates new access token
                        if not isReadOnlyMode
                            user.resetToken(req)
                            info =
                                lang: lang
                                plat: plat
                                device_token: device_token
                                last_ip: ip_address

                            mm.UserProfile.update {_id: user._id}, {info: info, access_token: user.access_token}, (err, updatedUser) ->
                                GameInn.SendEvent 'BATTLE_SEARCH', {userID: req.castle.user._id, foundUserID: enemy._id}, (err, data) ->
                                    if err?
                                        console.log err
                                
                                view = new mv.UserProfile(user, {balconomy: req.app.castle.balconomy, user: user})
                                view.export (err, obj) ->
                                    res.json
                                        access_token: user.access_token
                                        last_access_token_days_delta : 0
                                        access_created : user.info.access_created
                                        user: obj
                                        balconomy: req.app.castle.balconomy.get()
                                        ts: Date.now()
                        else
                            return next new ex.ServiceReadonlyMode()

                (type) ->


                    if not isReadOnlyMode

                        ip_address = req.headers['x-forwarded-for'] || req.connection.remoteAddress

                        mm.FailedAuth.create { username:req.body.username,ip: ip_address }, (err, failedAuth) ->
                            if err?
                                return next err

                            return next new ex.AuthFailed
                    else
                        return next new ex.AuthFailed
                (error) ->
                    return next new ex.InternalServerError
            )
