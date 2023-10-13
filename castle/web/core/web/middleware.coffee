# Defines common Express middleware.
zlib = require 'zlib'
express = require 'express'
connect = require 'connect'


# Do nothing and move on to the next handler.
exports.noop = noop = (req, res, next) ->
    next()


# Exposes raw request body as binary buffer. In most cases it should be used
# as the last body parser in middleware chain.
exports.rawBody = (options) ->
    options = options || {}
    limit = if options.limit? then express.limit(options.limit) else noop

    return (req, res, next) ->
        if req._body
            return next()

        req.body = req.body || {}
        #flag as parsed
        req._body = true

        limit req, res, (err) ->
            if err
                return next err

            buf = []

            req.on 'data', (chunk) ->
                buf.push chunk
            req.on 'end', ->
                req.rawBody = Buffer.concat buf

                next()


exports.json = (options) ->
    options = options || {}
    strict = if options.strict == false then false else true
    limit = if options.limit then express.limit(options.limit) else noop

    parseData = (req, res, next, data) ->
        buf = data.toString 'utf-8'

        if strict and '{' != buf[0] and '[' != buf[0]
            err = new Error 'invalid json'
            err.status = 400

            return next err

        try
            req.body = JSON.parse buf, options.reviver

            return next()
        catch err
            err.body = buf
            err.status = 400

            return next err

    return (req, res, next) ->
        if req._body
            return next()

        req.body = req.body || {}

        if 'application/json' != connect.utils.mime(req)
            return next()

        req._body = true

        limit req, res, (err) ->
            if err
                return next err

            buf = []

            req.on 'data', (chunk) ->
                buf.push chunk

            req.on 'end', ->
                data = Buffer.concat buf

                if req.get('Content-Encoding') == 'gzip'
                    zlib.gunzip data, (err, data) ->
                        if err
                            return next err

                        parseData req, res, next, data
                else
                    parseData req, res, next, data
