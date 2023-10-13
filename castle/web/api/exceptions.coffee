# Defines errors handled and returned by the API.
apiconfig = require './apiconfig'
ver = apiconfig.version.current

ustr = require 'underscore.string'
mm = require "./#{ver}/db/mongodb/models"
util = require 'util'


exports.APIError = class APIError extends Error
    extra: {}

    constructor: ->
        @name = 'APIError'

    getDescription: ->
        return @meta.description ? null

    getData: ->
        return null

    getURI: ->
        return @meta.uri ? null


exports.InternalServerError = class InternalServerError extends APIError
    meta:
        statusCode: 500
        type: 'INTERNAL_SERVER_ERROR'
        description: 'An internal server error occured'

    getDescription: ->
        return @meta.description


exports.NotImplemented = class NotImplemented extends APIError
    meta:
        statusCode: 501
        type: 'NOT_IMPLEMENTED'
        description: 'Requested feature is not implemented'


exports.NotFound = class NotFound extends APIError
    meta:
        statusCode: 404
        type: 'RESOURCE_NOT_FOUND'

    constructor: (id, name=null) ->
        @extra.id = id
        @extra.name = name

    getDescription: ->
        if @extra.name
            return "#{ustr.capitalize(@extra.name)} id:#{@extra.id} was not found"
        else
            return "Resource id:#{@extra.id} was not found"

    getData: ->
        return {id: @extra.id, name: @extra.name}


exports.URINotFound = class URINotFound extends APIError
    meta:
        statusCode: 404
        type: 'URI_NOT_FOUND'
        description: 'Invalid URI or method'


exports.Unauthorized = class Unauthorized extends APIError
    meta:
        statusCode: 401
        type: 'UNAUTHORIZED'
        description: 'Unauthorized request. Did you provide a valid access_token or app credentials?'

    constructor: (reason="") ->
        @extra.reason = reason

    getData: ->
        return {reason: @extra.reason}


exports.ServiceUnavailable = class ServiceUnavailable extends APIError
    meta:
        statusCode: 503
        type: 'SERVICE_UNAVAILABLE'
        description: "Castle API is currently down for maintanance",

exports.ServiceReadonlyMode = class ServiceReadonlyMode extends APIError
    meta:
        statusCode: 503
        type: 'SERVICE_READ_ONLY'
        description: "Castle API is currently switched to read only mode for maintanance",

exports.ServiceGatewayTimeout = class ServiceGatewayTimeout extends APIError
    meta:
        statusCode: 504
        type: 'GATEWAY_TIMEOUT'
        description: "Castle API is under heavy load. No worries though, we're working on fixing this!"

exports.SecureConnectionRequired = class SecureConnectionRequired extends APIError
    meta:
        statusCode: 401
        type: 'SECURE_CONNECTION_REQUIRED'
        description: 'Secure SSL connection is required to perform operation.'

exports.AuthFailed = class AuthFailed extends APIError
    meta:
        statusCode: 401
        type: 'AUTH_FAILED'
        description: 'Authentication failed (wrong credentials provided)'

    constructor: (reason="") ->
        @extra.reason = reason

    getData: ->
        return {reason: @extra.reason}


exports.AuthFailedTooManyAttempts = class AuthFailedTooManyAttempts extends APIError
    meta:
        statusCode: 401
        type: 'AUTH_FAILED_TO_MANY_ATTEMPTS'
        description: 'Authentication failed (too many attempts to login)'

exports.InvalidParameters = class InvalidParameters extends APIError
    meta:
        statusCode: 400
        type: 'INVALID_PARAMETERS'

    constructor: (params) ->
        @extra.params = params

    getDescription: ->
        return "Invalid values for parameters #{@extra.params}"

    getData: ->
        return {params: @extra.params}


exports.MissingParameters = class MissingParameters extends APIError
    meta:
        statusCode: 400
        type: 'MISSING_PARAMETERS'

    constructor: (params) ->
        @extra.params = params

    getDescription: ->
        return "Missing parameters #{@extra.params}"

    getData: ->
        return {params: @extra.params}


exports.MeValueRequired = class MeValueRequired extends APIError
    meta:
        statusCode: 400
        type: 'ME_VALUE_REQUIRED'
        description: 'Invalid resource ID. Expected "me"'


exports.Forbidden = class Forbidden extends APIError
    meta:
        statusCode: 403
        type: 'FORBIDDEN'
        description: 'You\'re not allowed to access this resource'

exports.BlockedUser = class BlockedUser extends APIError
    meta:
        statusCode: 403
        type: 'BLOCKED_USER'
        description: 'You are blocked'


exports.CommentsDisabled = class CommentsDisabled extends APIError
    meta:
        statusCode: 403
        type: 'COMMENTS_DISABLED'
        description: 'Comments disabled'

exports.ProfanityCheck = class ProfanityCheck extends APIError
    meta:
        statusCode: 403
        type: 'PROFANITY_CHECK'
        description: 'You\'re not allowed to type profanity words'

    constructor: (lockit="", reason ="") ->
        @extra.lockit = lockit
        @extra.reason = reason

    getData: ->
        return {lockit: @extra.lockit, reason: @extra.reason}


exports.InvalidGrantType = class InvalidGrantType extends APIError
    meta:
        statusCode: 400
        type: 'INVALID_GRANT_TYPE'
        description: 'Invalid grant type'

    constructor: (grantTypes) ->
        @extra.grantTypes = grantTypes

    getData: ->
        return {supported: @extra.grantTypes}

exports.InvalidPromoCode = class InvalidPromoCode extends APIError
    meta:
        statusCode: 400
        type: 'INVALID_PROMO_CODE'
        description: 'Invalid promo code'

    constructor: (promoCode) ->
        @extra.promoCode = promoCode

    getData: ->
        return {promo_code: @extra.promoCode}


exports.PromoCodeNotFound = class PromoCodeNotFound extends APIError
    meta:
        statusCode: 400
        type: 'PROMO_CODE_NOT_FOUND'
        description: 'Promo code not found'

exports.UserExists = class UserExists extends APIError
    meta:
        statusCode: 400
        type: 'USER_EXISTS'
        description: 'User already exists'

    constructor: (properties) ->
        @extra.properties = properties

    getData: ->
        return {properties: @extra.properties}


exports.ValidationError = class ValidationError extends APIError
    meta:
        statusCode: 400
        type: 'VALIDATION_ERROR'
        description: 'Provided values are not valid'

    constructor: (properties) ->
        @extra.properties = properties

    getData: ->
        return {properties: @extra.properties}


exports.UploadError = class UploadError extends APIError
    meta:
        statusCode: 500
        type: 'UPLOAD_ERROR'
        description: 'And error occured whilst uploading data. Try again in a minute.'


exports.DownloadError = class DownloadError extends APIError
    meta:
        statusCode: 500
        type: 'DOWNLOAD_ERROR'
        description: 'And error occured whilst downloading data. Try again in a minute.'

exports.IAPValidationError = class IAPValidationError extends APIError
    meta:
        statusCode: 400
        type: 'IAP_VALIDATION_ERROR'
        description: 'IAP internal validation error'
        
exports.ResetRequired = class ResetRequired extends APIError
    meta:
        statusCode: 400
        type: 'RESET_REQUIRED'
        description: 'Reset flag was enabled in UserProfile'

    constructor: (lockit="", reason ="", data="") ->
        @extra.lockit = lockit
        @extra.reason = reason
        mongoData =
            lockit: lockit
            reason: reason
            data: data
        if lockit != 'INACTIVITY_LOGOUT'
            mm.Error.create mongoData, (err, obj) ->
                if err?
                    util.log '[ERROR] couldnt save ResetRequired exception to Mongo'

    getData: ->
        return {lockit: @extra.lockit, reason: @extra.reason}

exports.Maintenance = class Maintenance extends APIError
    meta:
        statusCode: 400
        type: 'MAINTENANCE'
        description: 'Maintenance in progress'

exports.APIValidationError = class APIValidationError extends APIError
    meta:
        statusCode: 400
        type: 'UPDATE_REQUIRED'
        description: 'Update application required'

exports.ResourceLocked = class ResourceLocked extends APIError
    meta:
        statusCode: 423
        type: 'RESOURCE_LOCKED'
        description: 'Access to the resource is locked right now'

    constructor: (lockit="", reason ="") ->
        @extra.lockit = lockit
        @extra.reason = reason

    getData: ->
        return {lockit: @extra.lockit, reason: @extra.reason}

exports.BattleOnline = class BattleOnline extends APIError
    meta:
        statusCode: 400
        type: 'BATTLE_ONLINE'
        description: 'Battle is online'

    