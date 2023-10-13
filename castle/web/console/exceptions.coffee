exports.CError = class CError extends Error
    constructor: (@status, @message) ->
        @name = 'CError'


exports.NotFound = class NotFound extends CError
    constructor: (@resource, @id) ->
        super 404, "#{resource}:#{id} was not found"


exports.Forbidden = class Forbidden extends CError
    constructor: (@resource, @id) ->
        super 403, "You're not allowed to access #{resource}:#{id}"


exports.InternalServerError = class InternalServerError extends CError
    constructor: (message) ->
        super 500, message
