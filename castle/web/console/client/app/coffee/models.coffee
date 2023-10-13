castle.models = models = {}


Model = class models.Model extends Backbone.Model
    resource: 'object'

    urlRoot: ->
        return castle.config.API_URL + @ROOT_URL

    fetch: (options) ->
        options = if options? then _.clone options else {}

        if not options.parse?
            options.parse = true

        success = options.success

        options.success = (response, status, xhr) =>
            data = response[@resource]

            if not @set(@parse data, options)
                return false

            if success?
                success @, data, options

        return @sync 'read', @, options

    #: Remove this when Backbone > 0.9.9 is released
    _computeChanges: (loud) ->
        @changed = {}
        already = {}
        triggers = []
        current = @_currentAttributes
        changes = @_changes

        for i in [changes.length - 2..0] by -2
            key = changes[i]
            val = changes[i + 1]

            if already[key]
                continue

            already[key] = true

            # Uses _.isEqual to test for equality
            if not _.isEqual current[key], val
                @changed[key] = val

                if not loud
                    continue

                triggers.push key, val
                current[key] = val

        if loud
            @_changes = []

        @_hasComputed = true

        return triggers


class models.User extends Model
    ROOT_URL: '/v1/users'
    resource: 'user'


class models.Level extends Model
    ROOT_URL: '/v1/levels'
    resource: 'level'

    fetchWithoutData: (options) ->
        options = options ? {}

        return @fetch options
