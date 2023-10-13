# Defines Castle API-specific Express middleware.

express = require 'express'
u = require 'underscore'

mm = require './db/mongodb/models'
ex = require './../exceptions'
util = require 'util'
apiconfig = require '../apiconfig'

# Enables CORS support.
#
# `options.domains`: A string or array of strings with allowed domains.
# Use `*` to allow free-for-all access.
exports.cors = (options) ->
    return (req, res, next) ->
        if req.headers.origin?
            domains = options.domains
            domains = [domains] if u.isString domains


            origin = req.headers.origin

            if origin in domains or '*' in domains
                res.set {
                    'Access-Control-Allow-Origin': origin
                    'Access-Control-Allow-Headers': 'X-Requested-With, X-Castle-Auth'
                }

                if req.method.toUpperCase() == 'OPTIONS'
                    res.set {
                        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS'
                        'Access-Control-Allow-Headers': req.get 'Access-Control-Request-Headers'
                        #'Access-Control-Expose-Headers': ''
                        #'Access-Control-Allow-Credentials': true # For Cookies support
                        'Access-Control-Max-Age': 86400 #24h
                    }

                    return res.send 200

        return next()


# Authenticates the request in accordance to Castle API's OAuth
# implementation.
#
# Exposes application and user information under `castle` property of the
# request object.
#
# The order of processing is as follows:
# 1. CORS (is CORS header present?; sets app info).
# 2. Credentials given in `X-Castle-Auth` header.
# 3. Fallback to query parameters.
# 4. Access token processing (sets user and app info, if not set).
# 5. Client ID and Client Secret processing (sets app info, if not set).
exports.authenticate = (options) ->
    return (req, res, next) ->
        req.castle =
            user: null
            app: null

        isSecure = req.headers['x-forwarded-proto'] == 'https'


        origin = res.get 'Access-Control-Allow-Origin'

        if origin?
            req.castle.app =
                name: if '//' in origin then origin.split('//')[1] else origin
                origin: origin

        credentials = req.get options.header

        if credentials?
            if credentials.indexOf(':') > -1
                [client_id, client_secret] = credentials.split ':', 2
            else
                access_token = credentials

        access_token = req.query.access_token if req.query.access_token

        if access_token?

            #if not isSecure
            #    return next new ex.SecureConnectionRequired

            mm.UserProfile.where('access_token', access_token).findOne (err, user) ->

                if user? and user.access_token != ''
                    if "deleted" in user.flags
                        return next new ex.Unauthorized('ban')

                    req.castle.user = user
                    req.castle.access_token = user.access_token
                    req.castle.device_token = user.info.device_token || ''
                    req.castle.lang = user.info.lang || (req.headers['lang'] || 'en')
                    req.castle.plat = user.info.plat || (req.headers['x-plat'] || 'any')

                    if not req.castle.app?
                        req.castle.app =
                            name: options.app.name

#                        cache.setex authKey, 15, JSON.stringify {user: doc.user, app: req.castle.app, access_token : access_token, device_token : doc.device_token, lang:req.castle.lang, plat:req.castle.plat}

                return next()
        else
            #Client-based app authentication
            client_id ?= req.query.client_id ? req.body.client_id
            client_secret ?= req.query.client_secret ? req.body.client_secret

            if client_id? and client_secret?
                if client_id == options.app.client_id and client_secret == options.app.client_secret
                    req.castle.app =
                        name: options.app.name

            return next()


exports.lastSeenCheck = (req, res, next) ->
#    return next()
    if req.castle.user?
        if req.headers['x-debug']?
            return next()

        if req.castle.user.resetRequired == true
            #close game if not already closed
            return next()

        if req.castle.user.profileType != 'PLAYER'
            return next()

        lastActivity = req.castle.user.last_user_activity

        if Date.now() - lastActivity > 300000
            # more than 5 minutes of idle occurs with reset, current game is over
            req.castle.user.resetRequired = true
            req.castle.user.resetMessage = 'INACTIVITY_LOGOUT'
            query = {"user":req.castle.user._id, "game.end": null}
            mm.RetentionHistory.findOne query, (err, retHist) ->
                if err
                    util.log '[ERROR] Getting retention history from database at lastSeenCheck'
                    next new ex.InternalServerError()
                else if retHist
                    retHist.closeGame lastActivity, (err) ->
                    #retHist.game.end = lastActivity
                    #retHist.save (err, retentionHistory) ->
                        if err
                            util.log '[ERROR] Closing game after inactivity at lastSeenCheck'
                            next new ex.InternalServerError()
        else
            req.castle.user.last_user_activity = Date.now()

        req.castle.user.save (err, data) ->
            if err?
                util.log '[ERROR] Saving user at lastSeenCheck'
                next new ex.InternalServerError()
            else
                next()
    else
        next()


exports.anonymousUser =
    _id:null
    username: 'anonymous'
    display_name: 'anonymous'
    email: 'anonymous@castle.com'
    password: ''
    joined: Date.now
    friends: []
    roles: []
    flags: []
    has_avatar: false
    isAdmin : false
    isAnonymous : true

# Checks whether user has been successfully authenticated. (if not, anonymous will be introduced)
exports.userOrAnonymousRequired = (req, res, next) ->

    if not req.castle.user?
        req.castle.user = exports.anonymousUser

    return next()

exports.userOrAnonymousWithAppRequired = (req, res, next) ->

    if not req.castle.app?
        return next new ex.Unauthorized

    if not req.castle.user?
        req.castle.user = exports.anonymousUser

    return next()



# Checks whether user has been successfully authenticated.
exports.userRequired = (req, res, next) ->
    if not req.castle.user?
        return next new ex.Unauthorized

    if req.castle.user.resetRequired == true
        return next new ex.ResetRequired req.castle.user.resetMessage

    return next()


# Checks whether app has been successfully authenticated.
exports.appRequired = (req, res, next) ->
    if not req.castle.app?
        return next new ex.Unauthorized

    return next()


# Checks whether authenticated user is an admin
exports.adminRequired = (req, res, next) ->
    if not (req.castle.user? and req.castle.user.isAdmin)
        return next new ex.Unauthorized

    return next()

exports.exceptionThrower  = (options) ->
    return (req, res, next) ->


        exceptionType   = req.headers['x-throw-exception']

        if exceptionType
            method = req.method.toUpperCase()

            exceptionTypeForMethods  = req.headers['x-throw-exception-for-methods']?.split(' ') || ['GET','PUT','POST','DELETE']

            if not (method in exceptionTypeForMethods)
                return next()

            exceptionParams = req.headers['x-throw-exception-params']

            for typeName,typeObj of ex
                if typeObj.prototype.meta and typeObj.prototype.meta.type
                    if typeObj.prototype.meta.type == exceptionType
                        return next new typeObj()
                    else if typeName == exceptionType
                        return next new ex[exceptionType](exceptionParams || {})

        return next()

exports.checkApplicationVersion = (req, res, next) ->
    applicationversion = req.headers.applicationversion
    if not req.headers.applicationversion or apiconfig.version.applications.indexOf(applicationversion) == -1
        return next new ex.APIValidationError

    return next()