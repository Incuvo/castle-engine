http = require 'http'
express = require 'express'
middleware = require '../core/web/middleware'
webassets = require '../core/web/webassets'
config = require './config'
ex = require './exceptions'
httpProxy = require 'http-proxy'

routes =
    main: require './routes/main'


app = module.exports = express()

app.castle = {}

#Configuration
env = app.get 'env'
appConfig = config.forEnvironment env

app.castle.config = appConfig

app.set 'view engine', 'jade'
app.set 'views', __dirname + '/views'

# app.use express.compress()
#app.use express.bodyParser()
#app.use middleware.rawBody()
#app.use express.methodOverride()
app.use express.static __dirname + '/public'
app.use app.router

port = 3000

#Production
if env == 'production'
    app.use (err, req, res, next) ->
        error = if err instanceof ex.CError then err else new CError(500, "#{err.name}: #{err.message}")

        # console.log

        return res.status(error.status).render 'error', {error: error}
else
    app.use (err, req, res, next) ->
        if err instanceof ex.CError
            return console.log err.status, err.message

        return next err

    app.use express.errorHandler {dumpExceptions: true, showStack: true}

# Add support for CDN
app.locals.assets = webassets __dirname + '/.castle-console.manifest', {removePrefix: 'public'}

paths = [
    '/',
    '/sign-up',
    '/sign-in',
    '/forbidden',
    '/levels',
    '/levels/:id',
    '/users',
    '/users/:id',
    '/users/:id/levels'
]

for path in paths
    app.get path, routes.main.app

#Server health check
app.head '/_internal/server/health/rejbuh9tbwf9x7jm', (req, res) ->
    res.send 200

proxy = new httpProxy.RoutingProxy()

#Default handler
app.all '/*', (req, res) ->
    return proxy.proxyRequest(req, res, { port : 4000, host: 'localhost'})
    #return next new ex.NotFound 'URI', req.path


#HTTP Server
httpServer = http.createServer app
httpServer.listen port

#Process config
process.title = "Castle Console [:#{port}; #{env}]"

process.on 'SIGTERM', ->
    console.log '[Castle Console] Received kill signal (SIGTERM), shutting down gracefully.'

    httpServer.close ->
        console.log '[Castle Console] Closed out remaining connections.'
        process.exit()

    setTimeout ->
        console.error '[Castle Console] Could not close connections in time, forcefully shutting down.'
        process.exit 1
    , 30*1000

console.log "[Castle Console] Listening on port %d in %s mode", port, env

exports.httpServer = httpServer
