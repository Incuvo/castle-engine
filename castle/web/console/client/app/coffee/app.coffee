class castle.Router extends Backbone.Router
    routes:
        '': 'hIndex'
        'sign-up': 'hSignUp'
        'sign-in': 'hSignIn'
        'forbidden': 'hForbidden'
        'users': 'hUsers'
        'users/:id': 'hUser'
        'users/:id/levels': 'hUserLevels'
        'levels': 'hLevels'
        'levels/:id': 'hLevel'

    initialize: (@app) ->
        @$root = $ '#root'

    route: (route, name, cb) ->
        super route, name, =>
            callback = if cb? then cb else @[name]

            @trigger 'route:@before'

            @before route, name
            callback.apply @, arguments
            @after route, name

            @trigger 'route:@after'

    before: (route, name) ->
        if not @app.context.get('access_token')?
            @app.context.set 'next', if route not in ['sign-up', 'sign-in'] then route else ''

            if route not in ['sign-up', 'sign-in', 'forbidden']
                return @navigate 'sign-in', {trigger: true}
        else
            user = @app.context.get 'user'

            if 'admin' not in user.roles
                return @navigate 'forbidden', {trigger: true}

            if not @view? or @view not instanceof castle.views.RootView
                @view?.destroy()
                @view = (new castle.views.RootView {app: @app}).appendTo @$root

    after: (route, name) ->

    hSignUp: =>
        @view?.destroy()
        @view = (new castle.views.SignUpView {app: @app}).appendTo @$root

    hSignIn: =>
        @view?.destroy()
        @view = (new castle.views.SignInView {app: @app}).appendTo @$root

    hForbidden: =>
        @view?.destroy()
        @view = (new castle.views.ForbiddenView {app: @app}).appendTo @$root

    hIndex: =>
        @view.showContent 'dashboard'

    hUsers: =>
        @view.showContent 'users'

    hUser: (id) =>
        @view.showContent 'user', {userId: id}

    hUserLevels: (id) =>
        @view.showContent 'levels', {filters: {owner: id}}

    hLevels: =>
        @view.showContent 'levels'

    hLevel: (id) =>
        @view.showContent 'level', {levelId: id}


class castle.Context
    set: (name, value) ->
        if value == undefined
            throw new Error 'Cannot set value to undefined'

        if not _.isString value
            value = JSON.stringify value

        localStorage[name] = value

        return @

    get: (name) ->
        if name not of localStorage
            return undefined

        value = localStorage[name]

        if value[0] in ['{', '[']
            try
                value = JSON.parse value
            catch e

        return value

    delete: (name) ->
        if name of localStorage
            delete localStorage[name]

        return @

    hasKey: (name) ->
        return name of localStorage


class castle.EventBus
    constructor: ->
        _.extend @, Backbone.Events


class castle.Application
    constructor: ->
        @eventBus = new castle.EventBus
        @router = new castle.Router @
        @context = new castle.Context
        @config = castle.config

    run: ->
        sync = Backbone.sync
        context = @context

        Backbone.sync = (method, model, options) ->
            beforeSend = options.beforeSend

            options.beforeSend = (xhr) ->
                accessToken = context.get 'access_token'

                if accessToken?
                    xhr.setRequestHeader 'X-Castle-Auth', accessToken

                if beforeSend?
                    return beforeSend xhr

            sync method, model, options

        Backbone.history.start {pushState: true}
