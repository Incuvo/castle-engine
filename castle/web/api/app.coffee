apiconfig = require './apiconfig'
ver = apiconfig.version.current
cluster = require 'cluster'
util    = require 'util'
fs      = require 'fs'
sysInfo = require "./#{ver}/systemInfo" # newest API here
moment  = require 'moment'

process.chdir('/home/ubuntu')

port = if process.argv.length > 2 then process.argv[2] else 4000
env = if 'NODE_ENV' of process.env then process.env.NODE_ENV else 'development'


if cluster.isMaster

    express = require 'express'
    http    = require 'http'
    mw      = require "./#{ver}/middleware" # newest API here for cluster master
    schedule = require 'node-schedule'
    mongoose = require 'mongoose'
    redis   = require 'redis'

    stats = []
    numCPUs = require('os').cpus().length

    for i in [0..numCPUs]
        cluster.fork()

    #Process config
    process.title = "CASTLE API [:#{port}; #{env}]"

    process.on 'SIGTERM', ->
        util.log '[WARN] Received kill signal (SIGTERM), shutting down gracefully.'

        cluster.disconnect ->
            util.log '[WARN] Closed out remaining connections.'

    # process.on 'message', (msg) ->

    # cluster.on 'fork', (worker) ->

    cluster.on 'online', (worker) ->
        util.log '[CASTLE API] Worker <id:#{worker.id}> just went online.'

    cluster.on 'listening', (worker, address) ->
        util.log "[CASTLE API] Worker <id:#{worker.id}> is listening on port #{address.port} in #{env} mode."

    cluster.on 'disconnect', (worker) ->
        worker.destroy()

        util.log "[WARN] Worker <id:#{worker.id}> has disconnected."

    cluster.on 'exit', (worker, code, signal) ->
        util.log "[WARN] Worker <id:#{worker.id}> has exited with <code:#{code}, signal:#{signal}>."

        if Object.keys(cluster.workers).length == 0
            setTimeout ->
                util.log "[WARN] Master exiting ..."
                process.exit 1
            ,1000


    startupWorkersCount = Object.keys(cluster.workers).length

    for id, worker of cluster.workers

        stats[id] = {}

        worker.on 'message', do (id,worker) ->
            (msg) ->
                if msg.stats
                    stats[id] = msg.stats


    app = express()
    app.use mw.cors {domains: '*'}


    memory_usage_percent = {}

    setInterval ->
        sysInfo.getGlobalMemoryStat (err, info) ->
            if err?
                return
            memory_usage_percent = info.usage_in_perc
    ,1000

    app.get '/status', (req, res) ->

        stats[0] =
            timestamp : Date.now()
            pid: process.pid,
            memory: process.memoryUsage(),
            uptime: process.uptime()
            swc : startupWorkersCount
            cwc : Object.keys(cluster.workers).length
            mup : memory_usage_percent

        res.json(stats)

    appContext = {}
    config  = require "./#{ver}/config" # newest API here
    mm      = require "./#{ver}/db/mongodb/models" # newest API here

    appContext.config = config.forEnvironment env
    appContext.mongoose = mongoose.connect "mongodb://#{appContext.config.mongodb.host}:#{appContext.config.mongodb.port}/#{appContext.config.mongodb.db}",
        server:
            #readPreference : 'secondary'
            auto_reconnect: true
            poolSize: 20
            socketOptions:
                keepAlive : 1
                #connectTimeoutMS: 1000
                #socketTimeoutMS : 10000

    appContext.redis = redis.createClient(appContext.config.redis.dbs.port, appContext.config.redis.dbs.host)
    appContext.redis.select appContext.config.redis.dbs.cache



#    tasks = exports.tasks = {}
#
#    tasksDir = "#{__dirname}/#{ver}/tasks/" # newest API here
#    fs.readdirSync(tasksDir).forEach ( taskScript ) ->
#        if  taskScript.match(/[^\.].*?\.coffee$/)
#            name = taskScript.replace(/\.coffee$/, '')
#
#            taskModule = require(tasksDir + name)
#
#            tryLock = (cb) ->
#                expires = moment().add(120, 'seconds').unix()
#                lockKey = "__tryLock_#{name}"
#
#                appContext.redis.setnx lockKey, expires, (err, response) ->
#                    if err
#                        util.log("[WARN] Something went wrong during aquiring the lock for task:#{name} err:#{err}")
#                        return
#
#                    if response == 1
#                        cb do (expires) ->
#                            () ->
#                                if expires == null
#                                    return
#
#                                if moment().unix() < expires
#                                    expires = null
#                                    appContext.redis.del lockKey, (err) ->
#                                        if err
#                                            util.log("[WARN] Something went wrong during release the lock for task:#{name} err:#{err}")
#                                            return
#                                else
#                                    util.log("[WARN] To late for release the lock for task:#{name} err:#{err}")
#                    else
#                        appContext.redis.get lockKey, (err, keyExpiresStr) ->
#                            if err
#                                util.log("[WARN] Something went wrong during get the lock for task:#{name} err:#{err}")
#                                return
#
#                            keyExpires = parseInt(keyExpiresStr)
#
#                            if moment().unix() > keyExpires
#                                util.log("[WARN] Auto lock reset after timeout for task:#{name}")
#                                appContext.redis.del lockKey, (err) ->
#                                    if err
#                                        util.log("[WARN] Something went wrong during release the lock for task:#{name} err:#{err}")
#                                        return
#
#                                    tryLock cb
#
#            task = taskModule(schedule, tryLock, appContext)
#            util.log('[CASTLE API] Add Task: '+ name)
#            tasks[name] = task

    httpServer = http.createServer app
    httpServer.listen 8000

    #Replays remove per 2 hours
    setInterval ->
        mm.Balconomy.getLastVersion (balconomy) ->

            removeTimestamp = Date.now() - 1209600000 # <- two weeks
            if(balconomy?)
                if(balconomy.config.replaysTimeInStorage?)
                    removeTimestamp = Date.now() - balconomy.config.replaysTimeInStorage
                    console.log 'storage found: ' + balconomy.config.replaysTimeInStorage

            mm.FightHistory.update {timestamp: {$lt: removeTimestamp}}, {$set:{replay: null}}, {multi: true}, (err, doc) ->
                if err?
                    console.log 'Replays remove error: ' + err

                timestampID = Math.floor(removeTimestamp / 1000).toString(16) + "0000000000000000"
                mm.Replay.remove {_id:{$lt: timestampID}}, (err, count) ->
                    if err?
                        console.log 'Replays remove error: ' + err

                    console.log 'Replays removed: ' + count
    ,7200000 # <- two hours

else
    # Module dependencies
    meld = require 'meld'
    underscore = require 'underscore'
    http = require 'http'
    express = require 'express'
    bodyParser = require 'body-parser'
    mongoose = require 'mongoose'
    redis = require 'redis'
    restful = require '../core/web/restful'
    IAPVerifier = require '../util/iap_verifier'
    iap         = require 'in-app-purchase'

    #middleware = require '../core/web/middleware'
    config = require "./#{ver}/config"
    mw = require "./#{ver}/middleware"
    ex = require './exceptions'
    elastical = require 'elastical'
    mm = require "./#{ver}/db/mongodb/models"
    Balconomy = require "./#{ver}/db/Balconomy"
    #locksmith = require 'locksmith'
    Leaderboard = require '../util/leaderboard'
    compress = require 'compression'
    methodOverride = require 'method-override'
#    tableify = require 'tableify'
    GameInn = require './../../../GameInn/index.js'

    routes =
        debug: require "./#{ver}/routes/debug"

        oauth_v6: require './v6/routes/oauth'
        api_v6: require './v6/routes/api'
        atomic_v6: require './v6/routes/atomic'
        api_v6_rest_model: require './v6/routes/rest-model'




    appConfig = config.forEnvironment env

    app = module.exports = express()

    app.castle =
        config: appConfig


    app.use compress()
    # app.use express.bodyParser()

    #Server health check
    app.use (req, res, next) ->
        if req.path == '/_internal/server/health/k19wi180a9ed9rdl'

            if app.castle.config.server.isDbErr
                return next new ex.InternalServerError
            else
                res.send({mode: app.castle.config.server.operationMode})
        else
            if app.castle.config.server.operationMode == 'r'

                method = req.method.toUpperCase()

                if req.path == "/#{ver}/auth" and method == 'POST'
                    next()
                else
                    if method == 'POST' or method == 'PUT'
                        return next new ex.ServiceReadonlyMode()
                    else
                        next()
            else
                next()






    #Use AOP for http statistic proxy

    globalMetric = require('measured').createCollection('all')

    metricStatsMethodsCollections =
        all : globalMetric

    meld.around express.Router.prototype, 'route', (methodCall) ->

        [method, path, callbacks...] = methodCall.args

        callbacks = underscore.flatten(callbacks)

        lastCallback = callbacks[ callbacks.length - 1 ]

        if path != '*'
            #and method in ['get','post','head','delete', 'options', 'trace']
            #console.log 'path:' + path + ' method:' + method

            methodCollections = metricStatsMethodsCollections[method]

            if not methodCollections?
                methodCollections = require('measured').createCollection(method)
                metricStatsMethodsCollections[method] = methodCollections


            callbacks[ callbacks.length - 1 ] = (req, res, next) ->

                stopWatcher = methodCollections.timer(path).start()

                res.on 'finish',() ->
                    stopWatcher.end()

                lastCallback.call(this, req, res, next)

        methodCall.proceed(method, path, callbacks)

    app.use (req, res, next) ->
        requestStopWatcher = globalMetric.timer('*').start()

        res.on 'finish',() ->
            requestStopWatcher.end()

        next()

    #app.use express.limit()

    #app.use middleware.json({limit : "5mb"})
    app.use bodyParser.urlencoded({ extended: false, limit: '1mb'})
    
    #app.use express.urlencoded()
    
    #app.use express.multipart()
    app.use bodyParser.json({limit: '5mb'})
    

    #app.use middleware.rawBody({limit : "1mb"})
    app.use methodOverride()
    app.use mw.cors appConfig.cors

    if env == 'staging'
        app.use mw.exceptionThrower appConfig


    #app.use express.static __dirname + '/public'

    app.use (req, res, next) ->

        if not req.app.castle.isDbConnected
                #try to force reconnection

            if not req.app.castle.isDbTryingReconnect
                req.app.castle.isDbTryingReconnect = true

                mm.ServerConfig.findOne {created : true}, (err, serverConfig) ->
                    req.app.castle.isDbTryingReconnect = false

            return res.json {
                error:
                    type: 'SERVICE_UNAVAILABLE'
                    description: "Castle API is currently down for maintanance"
                    uri: ""
                    data: ""
            }, 503
        next()

    deprecated = (req, res, next) ->
        return next new ex.APIValidationError

#    checkApiVersion = (req, res, next) ->
#        if (req.originalUrl.indexOf('v5') > -1 and req.headers['x-plat'] == 'AGP')
#            return deprecated(req, res, next)
#
#        return next()
#
#    app.use checkApiVersion
    app.use mw.checkApplicationVersion
    app.use mw.authenticate {header: 'X-Castle-Auth', app: appConfig.apps.castle}

    # here versioning is going to be needed
    app.use mw.lastSeenCheck

    #app.use app.router



    app.all '/v1/*', deprecated
    app.all '/v3/*', deprecated
    app.all '/v4/*', deprecated
    app.all '/v5/*', deprecated

    userActivity = (req, res, next) ->
        res.json
            status: 'ok'

    pathVersion = 'v6'

    app.get  '/' + pathVersion + '/tutorialCheck', mw.userRequired, routes.atomic_v6.tutorialCheck
    app.post '/' + pathVersion + '/userActivity', mw.userRequired, userActivity
    app.get  '/' + pathVersion + '/users/stats', mw.adminRequired, routes.api_v6.usersStats
    app.post '/' + pathVersion + '/profanityCheck', mw.userOrAnonymousWithAppRequired, routes.api_v6.profanityCheck
    app.post '/' + pathVersion + '/profanityCheck2', mw.userOrAnonymousWithAppRequired, routes.api_v6.profanityCheck2
    app.post '/' + pathVersion + '/iap/verify', mw.userRequired, routes.api_v6.iapVerify
    app.put  '/' + pathVersion + '/userUpdate/:id', mw.userRequired, routes.api_v6.userUpdate
    app.post '/' + pathVersion + '/auth', mw.appRequired, routes.oauth_v6.oauth
    app.get  '/' + pathVersion + '/getServerTime',  mw.userOrAnonymousWithAppRequired, routes.api_v6.getServerTime
    app.get  '/' + pathVersion + '/getPromoTime',  mw.userOrAnonymousWithAppRequired, routes.api_v6.getPromoTime
    app.get  '/' + pathVersion + '/getFightHistory', mw.userRequired, routes.api_v6.getFightHistory
    app.get  '/' + pathVersion + '/refreshMap', mw.userRequired, routes.api_v6.refreshMap
    app.get  '/' + pathVersion + '/getReplay', mw.userRequired, routes.api_v6.getReplay
    app.post '/' + pathVersion + '/uncoverCloud', mw.userRequired, routes.api_v6.uncoverCloud
    app.post '/' + pathVersion + '/findNewPlayer', mw.userRequired, routes.api_v6.findNewPlayer
    app.post '/' + pathVersion + '/postReplay', mw.userRequired, routes.api_v6.postReplay
    app.post '/' + pathVersion + '/init', mw.userOrAnonymousWithAppRequired, routes.api_v6.initGame
    app.get  '/' + pathVersion + '/getUserData/:id', mw.userRequired, routes.api_v6.getUserData
    app.post '/' + pathVersion + '/postStartBattle', mw.userRequired, routes.api_v6.startBattle
    app.post '/' + pathVersion + '/postFightDealedDamage', mw.userRequired, routes.api_v6.fightDealedDamage
    app.post '/' + pathVersion + '/postFightStars', mw.userRequired, routes.api_v6.fightStars
    app.post '/' + pathVersion + '/postFightShootProjectile', mw.userRequired, routes.api_v6.fightShootProjectile
    app.post '/' + pathVersion + '/postFightStealResources', mw.userRequired, routes.api_v6.fightStealResources
    app.post '/' + pathVersion + '/postEndBattle', mw.userRequired, routes.api_v6.endBattle
    app.post '/' + pathVersion + '/postDisplayName', mw.userRequired, routes.api_v6.postDisplayName
    app.post '/' + pathVersion + '/postLootCartCollect', mw.userRequired, routes.api_v6.postLootCartCollect
    app.post '/' + pathVersion + '/postCollectReward', mw.userRequired, routes.api_v6.postCollectReward
    app.post '/' + pathVersion + '/ExchangeResources', mw.userRequired, routes.atomic_v6.exchangeResources
    app.post '/' + pathVersion + '/BoostProduction', mw.userRequired, routes.atomic_v6.postBoostProduction
    app.post '/' + pathVersion + '/FinishBuildingImmediately', mw.userRequired, routes.atomic_v6.postFinishBuildingImmediately
    app.post '/' + pathVersion + '/FinishAmmoProduction', mw.userRequired, routes.atomic_v6.postFinishAmmoProduction
    app.post '/' + pathVersion + '/FinishResearchProjectileImmediately', mw.userRequired, routes.atomic_v6.postFinishResearchProjectileImmediately
    app.post '/' + pathVersion + '/BuyRoom', mw.userRequired, routes.atomic_v6.postBuyRoom
    app.post '/' + pathVersion + '/CancelBuildingRoom', mw.userRequired, routes.atomic_v6.postCancelBuildingRoom
    app.post '/' + pathVersion + '/DestroyFortification', mw.userRequired, routes.atomic_v6.postDestroyFortification
    app.post '/' + pathVersion + '/UpgradeRoom', mw.userRequired, routes.atomic_v6.postUpgradeRoom
    app.post '/' + pathVersion + '/ResearchProjectile', mw.userRequired, routes.atomic_v6.postResearchProjectile
    app.post '/' + pathVersion + '/ProduceAmmo', mw.userRequired, routes.atomic_v6.postProduceAmmo
    app.post '/' + pathVersion + '/collectResourceFromCollectors', mw.userRequired, routes.atomic_v6.collectResourceFromCollectors
    app.post '/' + pathVersion + '/FinishBuilding', mw.userRequired, routes.atomic_v6.postFinishBuilding
    app.post '/' + pathVersion + '/FlipFortification', mw.userRequired, routes.atomic_v6.postFlipFortification
    app.post '/' + pathVersion + '/SetRoomPosition', mw.userRequired, routes.atomic_v6.postSetRoomPosition
    app.post '/' + pathVersion + '/FinishResearchProjectile', mw.userRequired, routes.atomic_v6.postFinishResearchProjectile
    app.post '/' + pathVersion + '/FinishProjectile', mw.userRequired, routes.atomic_v6.postFinishProjectile
    app.post '/' + pathVersion + '/RemoveProjectile', mw.userRequired, routes.atomic_v6.postRemoveProjectile
    app.post '/' + pathVersion + '/GetStatistics', mw.userRequired, routes.atomic_v6.postGetStatistics
    app.post '/' + pathVersion + '/TutorialProgress', mw.userRequired, routes.atomic_v6.postTutorialProgress
    app.post '/' + pathVersion + '/StoryProgress', mw.userRequired, routes.atomic_v6.postStoryProgress
    app.post '/' + pathVersion + '/CancelAmmoProduction', mw.userRequired, routes.atomic_v6.postCancelAmmoProduction
    app.post '/' + pathVersion + '/LastNotificationVisible', mw.userRequired, routes.atomic_v6.postLastNotificationVisible
    app.post '/' + pathVersion + '/ShowLootCart', mw.userRequired, routes.atomic_v6.ShowLootCart
    app.post '/' + pathVersion + '/postFinishAmmoCommercial', mw.userRequired, routes.atomic_v6.postFinishAmmoCommercial
    app.post '/' + pathVersion + '/postFreeGemsCommercial', mw.userRequired, routes.atomic_v6.postFreeGemsCommercial
    app.post '/' + pathVersion + '/postCollectAchievement', mw.userRequired, routes.atomic_v6.postCollectAchievement
    app.post '/' + pathVersion + '/postRefillResources', mw.userRequired, routes.atomic_v6.postRefillResources
    app.get  '/' + pathVersion + '/getTopGlobalPlayers', mw.userRequired, routes.atomic_v6.getTopGlobalPlayers
    app.get  '/' + pathVersion + '/getLeague', mw.userRequired, routes.atomic_v6.getLeague
    app.post '/' + pathVersion + '/postFreeTutorialAmmo', mw.userRequired, routes.atomic_v6.postFreeTutorialAmmo
    app.post '/' + pathVersion + '/postClanEmail', mw.userRequired, routes.atomic_v6.postClanEmail
    app.post '/' + pathVersion + '/postUserRateApp', mw.userRequired, routes.atomic_v6.postUserRateApp


    app.post '/debug/changeCastle', mw.userRequired, routes.debug.debugChangeCastle
    app.get '/debug/debugTest', mw.userOrAnonymousRequired, routes.debug.debugTest
    app.get '/debug/getBalconomy', mw.appRequired, routes.debug.getBalconomy
    app.post '/debug/postBalconomy', mw.userOrAnonymousRequired, routes.debug.postBalconomy
    app.get '/debug/RemoveProjectiles', mw.userRequired, routes.debug.RemoveProjectiles
    app.get '/debug/AddProjectiles', mw.userRequired, routes.debug.AddProjectiles
    app.get '/debug/UpgradeProjectiles', mw.userRequired, routes.debug.UpgradeProjectiles
    app.get '/debug/DowngradeProjectiles', mw.userRequired, routes.debug.DowngradeProjectiles
    app.post '/debug/AddGems', mw.userRequired, routes.debug.AddGems
    app.get '/debug/check', routes.debug.checkErrors
    #app.get '/debug/iap', routes.debug.iap
    app.post '/debug/debugBuyRoom', mw.userRequired, routes.debug.debugBuyRoom
    app.post '/debug/iap', routes.debug.checkPurchase
    app.post '/debug/retention', routes.debug.checkRetention
    app.post '/debug/attackStats', routes.debug.checkAttackFights
#   tkowalski: HOTFIX FOR IOS PRODUCTION CLIENT
    app.post '/debug/iap/verify', mw.userRequired, routes.debug.iapVerify
    app.get '/debug/prepareDefenceFightHistory', mw.userRequired, routes.debug.prepareDefenceFightHistory

    #Default handler
    app.all '*', (req, res, next) ->
        return next new ex.NotImplemented

    app.use (err, req, res, next) ->

        if err instanceof ex.APIError
            return res.status(err.meta.statusCode).json {
                error:
                    type: err.meta.type
                    description: err.getDescription()
                    uri: err.getURI()
                    data: err.getData()
            }

        return next err


    #Production / Staging
    if env == 'production' or env == 'staging'
        app.use (err, req, res, next) ->
            if err not instanceof ex.APIError
                # served error "request.aborted"
                if err.type == 'request.aborted'
                    util.log "[WARN] Request aborted, length: #{err.expected}, received #{err.received} from " + (req.headers['x-forwarded-for'] || req.connection.remoteAddress) + ", method: " + req.method + ':' + req.originalUrl
                else
                    statusCode = if err.status? then err.status else 500

                    util.log "[ERROR] Unexpected error #{err.name}: #{err.message}"

                    util.log("----- HTTP -----")
                    util.log( (req.headers['x-forwarded-for'] || req.connection.remoteAddress) + ':' + req.method + ':' + req.originalUrl )
                    util.log(util.inspect(req.body))
                    util.log(util.inspect(req.query))
                    util.log(util.inspect(req.headers))
                    util.log("----- END HTTP -----")
                    util.log(util.inspect(err))

                    if err.stack
                        util.log("stack:")
                        util.log(util.inspect(err.stack))
                        util.log("--------------------")

                    res.json statusCode, {
                        error:
                            type: 'UNEXPECTED_SERVER_ERROR'
                            description: 'Unexpected server error has occured'
                    }
    else
        app.use express.errorHandler {dumpExceptions: true, showStack: true}

    #DBs
    app.castle.mongoose = mongoose.connect "mongodb://#{appConfig.mongodb.host}:#{appConfig.mongodb.port}/#{appConfig.mongodb.db}",
        server:
            #readPreference : 'secondary'
            auto_reconnect: true
            poolSize: 20
            socketOptions:
                keepAlive : 1
                #connectTimeoutMS: 1000
                #socketTimeoutMS : 10000

    app.castle.isDbConnected = false
    app.castle.isDbTryingReconnect = false

    app.castle.redis            = redis.createClient(appConfig.redis.dbs.port, appConfig.redis.dbs.host)
    app.castle.pub              = redis.createClient(appConfig.redis.dbs.port, appConfig.redis.dbs.host)
    app.castle.sub              = redis.createClient(appConfig.redis.dbs.port, appConfig.redis.dbs.host)
    app.castle.cache            = redis.createClient(appConfig.redis.dbs.port, appConfig.redis.dbs.host)
    app.castle.leaderboardRedis = redis.createClient(appConfig.redis.dbs.port, appConfig.redis.dbs.host)
    app.castle.leaderboardRedis.select appConfig.redis.dbs.leaderboard
    #app.castle.lock             = locksmith({redisClient : app.castle.cache, timeout: 60 * 10})
    app.castle.balconomy = new Balconomy()

    #leaderboard

    leaderboard_options =
        'pageSize': 16

    app.castle.leaderboard = new Leaderboard('highscores', leaderboard_options, app.castle.leaderboardRedis )

    GameInn.Init("AKIAIMSTHNTQ7POVVEEA", "Qr/f7zRIeO+lcRJDJnL8cx3WBt6JhUK86V2pt7Ty", "us-west-1", "CastleRevengeProduction", "incuvo-castlerevenge-events")

    connection = app.castle.mongoose.connection

    connection.on 'connected', ()->
        app.castle.balconomy.refreshBalconomy()

        mm.UserProfile.find().sort({nid: -1}).limit(1).exec (err, doc) ->
            if err?
                util.log "[ERROR] Getting natural user id"
            if doc.length == 0
                util.log "[WARNING] No NID in DB, using 0"
                nid = 0
            else
                nid = if doc[0].nid != undefined then doc[0].nid else 0
            util.log "[CASTLE API] Set Natural ID for default profiles: " + nid
            mm.Persistent.update {}, {$set: {nid: nid}}, {upsert: true}, (err, persistent) ->
                if err?
                    util.log "[ERROR] Setting NID " + err

        app.castle.isDbConnected = true
        app.castle.isDbTryingReconnect = false
        util.log('[CASTLE API] Connected to database')
    connection.on 'disconnected', ()->
        util.log('[ERROR] Disconnected from database')
        app.castle.isDbConnected = false
    connection.on 'close', () ->
        util.log('[WARN] Connection to database closed')
        app.castle.isDbConnected = false

    #iap
    if env == 'staging' || env == 'testing'
        app.castle.iap = new IAPVerifier( appConfig.iap.shared_secret, true, true)
        # console.log 'set sandbox'
    else
        app.castle.iap = new IAPVerifier( appConfig.iap.shared_secret )
        # console.log 'set production'

    iap.config( appConfig.iap )

    iap.setup (err) ->

        if err
            return util.log('[ERROR] IAP Error:' + err)

        return util.log('[CASTLE API] IAP Setup ok')

    app.castle.iapService = iap

    #Search engine (Elastic Search)
    app.castle.se = if appConfig.se.host? then new elastical.Client(appConfig.se.host, { port: appConfig.se.port }) else null

    #Redis
    app.castle.redis.select appConfig.redis.dbs.datastore
    app.castle.cache.select appConfig.redis.dbs.cache

    app.castle.sub.on "message", (channel, message) ->
        if channel == 'BALCONOMY'
            app.castle.balconomy.refreshBalconomy()
        else
            util.log '[ERROR] unknown channel on redis ' + channel


    app.castle.sub.subscribe 'BALCONOMY'

    checkServerOperationMode = (cb) ->

        mm.ServerConfig.findOne {created : true}, (err, serverConfig) ->

            if cb
                cb()

            if err
                app.castle.config.server.isDbErr = true
                util.log("[ERROR] No serverConfig!")
                return
            else
                app.castle.config.server.isDbErr = false

            if serverConfig and serverConfig.operation_mode

                if app.castle.config.server.operationMode != serverConfig.operation_mode
                    util.log("[CASTLE API] Entering to [#{serverConfig.operation_mode}] operation mode ...")

                app.castle.config.server.operationMode = serverConfig.operation_mode

    #checkServerOperationMode () ->

    #HTTP Server
    httpServer = http.createServer app
    httpServer.listen port

    process.on 'uncaughtException', (err,arg1) ->

        if (err.toString().indexOf('failed to connect') != -1) or (not app.castle.isDbConnected)
            return

        console.error (new Date).toUTCString() + '[ERROR] uncaughtException:', err.message
        console.error err.stack
        process.exit 1

    #process.on 'message', (msg) ->

    #send metrics stats to master


    cpu_stats = {}

    setInterval ->
        sysInfo.getProcessCPUStatPercent (err, info) ->
            if err?
                return
            cpu_stats = info
    ,1000


    setInterval ->
        checkServerOperationMode()
    ,10000

    setInterval ->
        process.send {stats: { timestamp : Date.now(), pid: process.pid, cpu : cpu_stats, memory: process.memoryUsage(), uptime: process.uptime(), http : ( metric.toJSON() for method, metric of metricStatsMethodsCollections ) } }
    ,1000
