# Allows for defining Express routes in RESTful manner. Support CRUD operations
# and nested resources.

express = require 'express'
u = require 'underscore'


# See [express-restful](https://github.com/christarnowski/express-restful)
# project.
express.application.restful = (path, callbacks...) ->
    len = callbacks.length

    if len == 0
        throw new Error "Missing callback(s) for route '#{path}'"
    else if len == 1
        middleware = []
        handlers = callbacks[0]
    else
        [middleware..., handlers] = callbacks

        middleware = u.flatten middleware

    if not handlers?
        throw new Error "Missing handlers definitions for route '#{path}'"

    id = 'id'

    if '$' of handlers
        if 'id' of handlers.$
            id = handlers.$.id

        if 'pre' of handlers.$
            middleware = middleware.concat handlers.$.pre

    objectPath = "#{path}/:#{id}"

    if 'list' of handlers
        @get path, middleware.concat handlers.list

    if 'create' of handlers
        @post path, middleware.concat handlers.create

    if 'read' of handlers
        @get objectPath, middleware.concat handlers.read

    if 'update' of handlers
        @put objectPath, middleware.concat handlers.update

    if 'delete' of handlers
        @delete objectPath, middleware.concat handlers.delete
