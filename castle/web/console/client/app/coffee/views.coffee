castle.views = views = {}


View = class views.View extends Backbone.View
    initialize: (options) ->
        super options

        @app = options.app
        @parent = options.parent ? null
        @children = {}

        @render()

    rerender: ->
        @undelegateEvents()
        @render()
        @delegateEvents()

        return @

    destroy: ->
        for id, view of @children
            view.destroy()

        @remove()

        # Unbind model event listeners

        return @

    update: (options) ->
        return @

    appendTo: ($el) ->
        $el.append @$el

        @delegateEvents()

        for id, view of @children
            view.delegateEvents()

        return @


class views.SignInView extends View
    template: JST.sign_in

    events:
        'click #sign-up-btn': (ev) ->
            ev.preventDefault()

            @app.router.navigate 'sign-up', {trigger: true}

        'click #sign-in-btn': (ev) ->
            ev.preventDefault()

            @$submit.prop 'disabled', true
            @$alert.fadeOut()

            data =
                grant_type: 'password'
                password: @$password.val()

            login = @$login.val()

            p = if '@' in login then 'email' else 'username'

            data[p] = login

            $.ajax "#{@app.config.API_URL}/v1/auth", {
                type: 'POST'
                data: JSON.stringify data
                contentType: 'application/json; charset=utf-8'
                dataType: 'json'
                success: (data) =>
                    @app.context.set 'access_token', data.access_token
                    @app.context.set 'user', data.user
                    @app.router.navigate @app.context.get('next'), {trigger: true}
                error: (jqXHR) =>
                    try
                        data = JSON.parse jqXHR.responseText

                        if data.error.type == 'AUTH_FAILED'
                            return @alert 'Wrong username/e-mail and password combination.'

                        console.log 'Authentication failed: ', jqXHR
                    catch e
                        console.log 'Failed to parse response: ', jqXHR

                    @alert 'Unexpected error occured. Please refresh the page and try again.'
                complete: =>
                    @$submit.prop 'disabled', false
            }

    render: ->
        ctx = {}

        @$el.html @template ctx

        @$alert = @$el.find '#sign-in-alert'
        @$login = @$el.find '#login'
        @$password = @$el.find '#password'
        @$submit = @$el.find '#sign-in-btn'

        return @

    alert: (message) ->
        @$alert.html message
        @$alert.fadeIn()


class views.SignUpView extends View
    template: JST.sign_up

    events:
        'click #sign-in-btn': (ev) ->
            ev.preventDefault()

            @app.router.navigate 'sign-in', {trigger: true}

        'click #sign-up-btn': (ev) ->
            ev.preventDefault()

            @$alert.fadeOut()

            email = @$email.val()
            username = @$username.val()

            if email == '' and username == ''
                return @alert 'E-mail and username cannot be empty'

            @$submit.prop 'disabled', true

            data =
                password: @$password.val()
                #roles: ['user', 'admin', 'console']

            if email != ''
                data.email = email

            if username != ''
                data.username = username

            $.ajax "#{@app.config.API_URL}/v1/users", {
                type: 'POST'
                data: JSON.stringify data
                contentType: 'application/json; charset=utf-8'
                dataType: 'json'
                success: (data) =>
                    @app.context.set 'access_token', data.access_token
                    @app.context.set 'user', data.user
                    @app.router.navigate '', {trigger: true}
                error: (jqXHR) =>
                    try
                        data = JSON.parse jqXHR.responseText
                        errorType = data.error.type

                        if errorType == 'USER_EXISTS'
                            values = for p, v of data.error.data.properties
                                v

                            values = values.join ', '

                            return @alert "User with given credentials already exists (#{values})"

                        if errorType == 'VALIDATION_ERROR'
                            properties = for p, v of data.error.data.properties
                                p

                            properties = properties.join ', '

                            return @alert "Provided values are not valid (#{properties})"

                        console.log 'Failed to create new user account: ', jqXHR
                    catch e
                        console.log 'Failed to parse response: ', jqXHR

                    @alert 'Unexpected error occured. Please refresh the page and try again.'
                complete: =>
                    @$submit.prop 'disabled', false
            }

    render: ->
        ctx = {}

        @$el.html @template ctx

        @$alert = @$el.find '#sign-up-alert'
        @$email= @$el.find '#email'
        @$username = @$el.find '#username'
        @$password = @$el.find '#password'
        @$submit = @$el.find '#sign-up-btn'

        return @

    alert: (message) ->
        @$alert.html message
        @$alert.fadeIn()


class views.ForbiddenView extends View
    template: JST.forbidden

    events:
        'click #sign-in-btn': (ev) ->
            ev.preventDefault()

            @app.router.navigate 'sign-in', {trigger: true}

        'click #sign-up-btn': (ev) ->
            ev.preventDefault()

            @app.router.navigate 'sign-up', {trigger: true}

    render: ->
        ctx = {}

        @$el.html @template ctx

        return @


class views.RootView extends View
    template: JST.main

    cache: {}

    navigation:
        user: 'users'
        level: 'levels'

    initialize: (options) ->
        super options

        @app.eventBus.on 'notification', (type, title, content) =>
            @children.toast.show type, title, content, 2000

        @app.eventBus.on 'showInfo', (type, title, content) =>
            @children.toast.show type, title, content, null

        @app.eventBus.on 'hideInfo', (type, title, content) =>
            @children.toast.hide()

    render: ->
        ctx = {}

        @$el.html @template ctx

        @$content = @$el.find '#content'
        @$topNav = @$el.find '#top-nav'
        @$sideNav = @$el.find '#side-nav'
        @$toast = @$el.find '#toast'

        @children =
            topNav: (new views.TopNavView({app: @app, parent: @})).appendTo @$topNav
            sideNav: (new views.SideNavView({app: @app, parent: @})).appendTo @$sideNav
            toast: (new views.ToastView({app: @app, parent: @})).appendTo @$toast

        return @

    showContent: (name, options) ->
        if @children.content?
            @children.content.remove()

        if name of @cache
            @children.content = @cache[name].appendTo(@$content).update options
        else
            className = "#{_.str.capitalize(_.str.camelize(name))}View"
            _options = _.extend({app: @app, parent: @}, options)

            @children.content = @cache[name] = (new views[className] _options).appendTo @$content

        navName = if name of @navigation then @navigation[name] else name

        @children.sideNav.select navName


class views.ToastView extends View
    template: JST.toast

    className: 'hide'

    render: (type, title, content) ->
        ctx =
            type: type ? 'warning'
            title: title ? null
            content: content ? null

        @$el.html @template ctx

        return @

    hide:  ->
        @$el.hide()

    show: (type, title, content, timeout) ->
        @render type, title, content

        @$el.show()

        if timeout?
            setTimeout =>
                @$el.hide()
            , timeout

        return @


class views.SideNavView extends View
    template: JST.side_nav

    current: null

    events:
        'click li a': (ev) ->
            ev.preventDefault()

            uri = $(ev.currentTarget).data('c-uri')
            handler = @app.router.routes[uri]

            @app.router.navigate uri
            @app.router[handler]()

    render: ->
        ctx = {}

        @$el.html @template ctx

        return @

    select: (name) ->
        @$el.find('.nav li').removeClass 'selected'
        @current = @$el.find("##{name}-view-sel")
        @current.addClass 'selected'

        return @


class views.TopNavView extends View
    template: JST.main_nav

    events:
        'click #settings-btn': (ev) ->
            ev.preventDefault()

            alert "I'm working on it, bro!"

        'click #logout-btn': (ev) ->
            ev.preventDefault()

            @app.context.delete('access_token').delete('user')
            @app.router.navigate 'sign-in', {trigger: true}

    render: ->
        user = @app.context.get 'user'

        ctx =
            user:
                name: if user.username? then user.username else user.email

        @$el.html @template ctx

        return @


class views.DashboardView extends View
    template: JST.dashboard

    events:
        'click #refresh-btn': (ev) ->
            @rerender()

    render: ->
        @fetchStats (stats) =>
            if @children.levelsStats?
                @children.levelsStats.remove()

            @children.levelsStats = (new views.LevelsStatsView {stats: stats, app: @app, parent: @}).appendTo @$levelsStats

        @$el.html @template {}

        @$levelsStats = @$el.find '#levels-stats'

        return @

    fetchStats: (success, error) ->
        accessToken = @app.context.get 'access_token'
        apiUrl = @app.config.API_URL

        async.parallel {
            levels: (cb) =>
                $.getJSON "#{apiUrl}/v1/levels/stats", {access_token: accessToken}, (data) ->
                    return cb null, data
            users: (cb) =>
                $.getJSON "#{apiUrl}/v1/users/stats", {access_token: accessToken}, (data) ->
                    return cb null, data
        }, (err, results) ->
            if err?.length not in [undefined, 0]
                console.log err

                if error?
                    return error err

            return success {
                levels: results.levels
                users: results.users
            }


class views.LevelsStatsView extends View
    template: JST.levels_stats

    events:
        'click .level-link': (ev) ->
            ev.preventDefault()

            @app.router.navigate $(ev.currentTarget).data('c-uri'), {trigger: true}

    initialize: (options) ->
        @_stats = options.stats

        super options

    render: ->
        ctx =
            stats: @_stats

        @$el.html @template ctx

        return @


class views.NewUserDialog extends View
    template: JST.user_new_dialog

    initialize: (options) ->
        @collection = options.collection || []
        super options

    events:
        'click #user-new-close-btn': (ev) ->
            $('#new-user-btn').prop 'disabled', false
            @remove()

        'click #user-new-create-btn': (ev) ->

            ev.preventDefault()

            @$alert.fadeOut()

            email = @$email.val()
            username = @$username.val()

            if email == '' or username == ''
                return @alert 'E-mail and username cannot be empty'


            roles = [];

            $('#user-new-roles  .btn.active').each (idx, selectionObj) ->
                roles.push( selectionObj.value )

            if roles.length == 0
                return @alert 'Please select roles'

            @$submit.prop 'disabled', true

            data =
                password: @$password.val()
                roles: roles

            if email != ''
                data.email = email

            if username != ''
                data.username = username

            access_token = @app.context.get 'access_token'

            $.ajax "#{@app.config.API_URL}/v1/users", {
                type: 'POST'
                data: JSON.stringify data
                contentType: 'application/json; charset=utf-8'
                dataType: 'json'
                beforeSend: (xhr) -> xhr.setRequestHeader 'X-Castle-Auth', access_token
                success: (data) =>
                    @collection.add data.user
                    @app.router.navigate 'users', {trigger: true}
                    @remove()
                    $('#new-user-btn').prop 'disabled', false

                error: (jqXHR) =>
                    try
                        data = JSON.parse jqXHR.responseText
                        errorType = data.error.type

                        if errorType == 'USER_EXISTS'
                            values = for p, v of data.error.data.properties
                                v

                            values = values.join ', '

                            return @alert "User with given credentials already exists (#{values})"

                        if errorType == 'VALIDATION_ERROR'
                            properties = for p, v of data.error.data.properties
                                p

                            properties = properties.join ', '

                            return @alert "Provided values are not valid (#{properties})"

                        console.log 'Failed to create new user account: ', jqXHR
                    catch e
                        console.log 'Failed to parse response: ', jqXHR

                    @alert 'Unexpected error occured. Please refresh the page and try again.'
                complete: =>
                    @$submit.prop 'disabled', false
            }

    render: ->
        @$el.html @template {}

        @$alert    = @$el.find '#user-new-alert'
        @$email    = @$el.find '#email'
        @$username = @$el.find '#username'
        @$password = @$el.find '#password'
        #@$roles    = @$el.find '#roles'
        @$submit   = @$el.find '#user-new-create-btn'

        return @

    alert: (message) ->
        @$alert.html message
        @$alert.fadeIn()

        return @

    show: ->
        ($ '#root').append @$el
        @$el.show()




class views.UsersView extends View
    template: JST.users

    initialize: (options) ->
        @_filters = {}

        super options

    events:
        'click #refresh-btn': (ev) ->
            @_filters = {}

            @rerender()

        'click #new-user-btn': (ev) ->

            $('#new-user-btn').prop 'disabled', true

            newUserDialog = (new views.NewUserDialog {collection: @collection, app: @app, parent: @})
            newUserDialog.show();


        'click #filter-btn': (ev) ->
            $filterEmail = @$el.find '#filter-email'
            $filterUsername = @$el.find '#filter-username'

            email = $filterEmail.val()
            username = $filterUsername.val()

            @_filters = {
                email: email if email != ''
                username: username if username != ''
            }

            @rerender()

    render: ->
        if @collection?
            @collection.stopListening()

        @collection = new castle.collections.UsersCollection null, {
            search:
                email: @_filters.email
                username: @_filters.username
        }

        @collection.on 'add', (model) =>
            @setUsersInfo @collection

        @collection.on 'remove', (model) =>
            @rerender()

        @collection.fetch {update: true, success: =>
            if @children.usersList?
                @children.usersList.remove()

            @children.usersList = (new views.UsersListView {collection: @collection, app: @app, parent: @}).appendTo @$usersList

            @$usersTotal.show()
        }

        @$el.html @template {filters: @_filters}

        @$usersList = @$el.find '#users-list'
        @$usersTotal = @$el.find '#users-total'

        return @

    setUsersInfo: (users) ->
        @$usersTotal.html "(#{users.length}/#{users.pagination.itemsTotal})"


class views.UsersListView extends View
    templates:
        list: JST.users_list
        item: JST.users_list_item

    initialize: (options) ->
        super options

        @collection.on 'add', (model) =>
            @$list.append $(@templates.item {user: model})

        @app.eventBus.on 'users.model.destroy', (model) =>
            @collection.remove model

        @app.eventBus.on 'users.model.update', (model) =>
            @collection.update model

            $user = @$list.find "#user-#{model.id}"

            email = model.get 'email'
            username = model.get 'username'

            $user.find('.login').html (if username? then username else email)
            $user.find('.login-secondary').html (if username? and email? then "(#{email})" else '')

    events:
        'click .media-list a': (ev) ->
            ev.preventDefault()

            @app.router.navigate $(ev.currentTarget).data('c-uri'), {trigger: true}

        'click #more-btn': (ev) ->
            @collection.page 'next', {update: true, remove: false}

            if @collection.pagination.currentPage == @collection.pagination.pagesTotal
                $(ev.currentTarget).hide()

    render: ->
        ctx =
            users: @collection
            templates:
                item: @templates.item

        @$el.html @templates.list ctx

        @$list = @$el.find '.media-list'

        return @


class views.UserView extends View
    template: JST.user

    initialize: (options) ->
        @userId = options.userId

        super options

    render: ->
        ctx =
            user:
                id: @userId

        @$el.html @template ctx

        @$userEdit = @$el.find '#user-edit'

        user = new castle.models.User {id: @userId}

        user.fetch success: =>
            if @children.userEdit?
                @children.userEdit.remove()

            @children.userEdit = (new views.UserEditView {model: user, app: @app, parent: @}).appendTo @$userEdit

        return @

    update: (options) ->
        @userId = options.userId

        return @render()


class views.UserEditView extends View
    template: JST.user_edit

    events:
        'click #save-btn': (ev) ->
            roles = @$roles.val()
            username = @$username.val()
            password = @$password.val();
            email = @$email.val()

            data =
                username: if username != '' then username else undefined
                email: if email != '' then email else undefined
                roles: if roles != '' then (_.str.trim(role) for role in roles.split(',')) else []


            if password != ''
                data['password'] = password;

            @app.eventBus.trigger 'notification', 'warning', null, 'Updating user...', null

            @model.save data, {
                success: (model, response) =>
                    @app.eventBus.trigger 'users.model.update', @model
                    @app.eventBus.trigger 'notification', 'success', null, 'User has been updated.'

                error: (model, xhr) =>
                    response = JSON.parse xhr.responseText
                    error = response.error
                    message = 'Failed to update user.'

                    switch error.type
                        when 'USER_EXISTS'
                            properties = []

                            for p, v of error.data.properties
                                properties.push "#{p}:#{v}"

                            message = "User [#{properties.join ', '}] already exists"
                        when 'VALIDATION_ERROR'
                            properties = []

                            for p, v of error.data.properties
                                properties.push "#{p}:#{v}"

                            message = "Validation failed for properties [#{properties}]"
                        else console.log response


                    @app.eventBus.trigger 'notification', 'error', null, message, 3000
            }

        'click #cancel-btn': (ev) ->
            @app.router.navigate 'users', {trigger: true}

        'click #delete-btn': (ev) ->
            @app.eventBus.trigger 'notification', 'warning', null, 'Removing level...', null

            @model.destroy success: (model, response) =>
                @app.eventBus.trigger 'users.model.destroy', @model
                @app.eventBus.trigger 'notification', 'success', null, 'User has been removed.'

            @app.router.navigate 'users', {trigger: true}

    render: ->
        ctx =
            user: @model

        @$el.html @template ctx

        @$username = @$el.find '#username'
        @$password = @$el.find '#password'
        @$email = @$el.find '#email'
        @$roles = @$el.find '#roles'

        return @


class views.LevelsView extends View
    template: JST.levels

    initialize: (options) ->
        options = options ? {}


        @_filters   = options.app.context.get('level_filters') || {}
        @isUserMode = false

        if not @_filters
            @_filters = options.filters ? {}

        @cacheInvalidateList = false
        super options



    events:
        'click #refresh-btn': (ev) ->
            @rerender()

        'click #levels-delete-btn': (ev) ->


            serialLevels = []
            self = @

            serialSetter = (level) ->
                return (cb) ->
                    level.destroy success: (level, response) =>
                        cb null, level
                    

            $('#levels-list  .checkbox').each (idx, selectionObj) ->
                if selectionObj.checked
                    serialLevels.push serialSetter new castle.models.Level {id: selectionObj.value}

            if serialLevels.length == 0
                return

            if not confirm("Do you want to delete levels ?")
                return

            @app.eventBus.trigger 'notification', 'warning', null, 'Removing levels...', null

            async.series serialLevels, (err, levels) ->

                for level in levels
                    self.app.eventBus.trigger 'levels.model.destroy', level

                self.app.eventBus.trigger 'notification', 'success', null, "Levels removed."
                self.app.router.navigate 'levels', {trigger: true}


        'click #new-level-btn': (ev) ->
            $('#new-level-btn').prop 'disabled', true

            newLevelDialog = (new views.NewLevelDialog {collection: @collection, app: @app, parent: @})
            newLevelDialog.show();

        'click #filter-btn': (ev) ->
            $filterTags = @$el.find '#filter-tags'
            $filterFlags = @$el.find '#filter-flags'
            $filterVisibility = @$el.find '#filter-visibility'

            $filterName = @$el.find '#filter-name'
            $filterDescription = @$el.find '#filter-description'

            $filterSortBy = @$el.find '#filter-sortby'
            $filterSortOrder = @$el.find '#filter-sortorder'

            $filterAny = @$el.find '#filter-any'

            tags = $filterTags.val()
            tags = if tags != '' then (_.str.trim(tag) for tag in tags.split(',')) else []

            flags = $filterFlags.val()
            flags = if flags != '' then (_.str.trim(flag) for flag in flags.split(',')) else []

            visibility = $filterVisibility.val()

            sortBy    = $filterSortBy.val()
            sortOrder = $filterSortOrder.val()

            @_filters = _.extend @_filters, {
                tag: tags.join '|' if tags.length
                flag: flags.join '|' if flags.length
                visibility: visibility
                sortby: sortBy
                sortorder: sortOrder
                description : $filterDescription.val() 
                name : $filterName.val()
                any : $filterAny.val()
            }

            ownerId = @$owner.val()
    
            if ownerId == '' and not @isUserMode
                delete @_filters['owner']
                delete @_filters['owner_name']

            if @$selectedOwnerId
                @_filters['owner'] = @$selectedOwnerId
                @_filters['owner_name'] = @$selectedOwnerName
                @$selectedOwnerId = null

            if not @isUserMode
                @app.context.set 'level_filters', @_filters

            @rerender()


    render: ->

        if @collection?
            @collection.stopListening()

        @collection = new castle.collections.LevelsCollection null, {
            search:
                tag: @_filters.tag
                flag: @_filters.flag
                visibility: @_filters.visibility
                owner: @_filters.owner
                sortBy: if @_filters.sortorder? then @_filters.sortorder + @_filters.sortby else '-created'
                description : @_filters.description
                name : @_filters.name
                any : @_filters.any
            populate: ['owner']
        }


        @collection.on 'add', (model) =>
            @setLevelsInfo @collection

        @collection.on 'remove', (model) =>
            @cacheInvalidateList = true
            @rerender()

        @collection.fetch {update: true, cacheInvalidateList : @cacheInvalidateList, success: =>
            if @children.levelsList?
                @children.levelsList.remove()

            @cacheInvalidateList = false
            @children.levelsList = (new views.LevelsListView {collection: @collection, app: @app, parent: @}).appendTo @$levelsList

            @$levelsTotal.show()
        }

        @$el.html @template {filters: @_filters}

        @$levelsList = @$el.find '#levels-list'
        @$levelsTotal = @$el.find '#levels-total'

        self = @

        @$owner = @$el.find '#filter-owner'
        @$owner.autocomplete({
            minLength : 2
            appendTo  : @$el
            select : (event, ui) =>
                self.$selectedOwnerId = ui.item.id
                self.$selectedOwnerName = ui.item.label
                self.$selectedOwnerEmail = ui.item.email
            source: ( request, response ) =>

                access_token = @app.context.get 'access_token'

                $.getJSON "#{@app.config.API_URL}/v1/users?username=" + request.term, {access_token: access_token}, (data) ->
                            response $.map data.users, ( user ) =>
                                return { label: user.username, value: user.username , id : user.id , email: user.email}

            }).autocomplete('widget').css('z-index', 2000);

        if @isUserMode
            @$owner.prop('disabled', true)
        else
            @$owner.prop('disabled', false)

        return @

    setLevelsInfo: (levels) ->
        @$levelsTotal.html "(#{levels.length}/#{levels.pagination.itemsTotal})"

    update: (options) ->
        options = options ? {}

        #if not _.isEqual @_filters, options.filters
        #    @_filters = options.filters ? {}
        #    return @rerender()

        if options.filters and options.filters.owner
            @_filters = options.filters
            @isUserMode = true
        else
            @isUserMode = false
            @_filters   = @app.context.get('level_filters') || {}

        return @rerender()


class views.LevelsListView extends View
    templates:
        list: JST.levels_list
        item: JST.levels_list_item

    initialize: (options) ->
        super options

        @selToggle = false

        @collection.on 'add', (model) =>
            @$list.append $(@templates.item {level: model})
            @rerender()

        @app.eventBus.on 'levels.model.destroy', (model) =>
            @collection.remove model

            @$list.find("#level-#{model.id}").remove()
            @rerender()

        @app.eventBus.on 'levels.model.update', (model) =>
            @collection.update model

            $level = @$list.find "#level-#{model.id}"
            $level.find('.name').html model.get('name')
            $level.find('.description').html model.get('description')
            @rerender()

    events:


        'click .media-list a': (ev) ->
            ev.preventDefault()

            @app.router.navigate $(ev.currentTarget).data('c-uri'), {trigger: true}


        'click #levels-select-all-btn': (ev) ->

            @selToggle = !@selToggle
            self = @

            levelsSelBtn = @$el.find '#levels-select-all-btn'

            if self.selToggle
                levelsSelBtn.innnerHTML = "Select All"
            else
                levelsSelBtn.innnerHTML = "Deselect All"

            $('#levels-list  .checkbox').each (idx, selectionObj) ->
                #console.log("#{idx} = #{selectionObj.value} (#{selectionObj.checked})")

                if self.selToggle
                    selectionObj.setAttribute("checked", 'checked')
                else
                    selectionObj.removeAttribute("checked")

        'click #more-btn': (ev) ->
            @collection.page 'next', {update: true, remove: false}

            if @collection.pagination.currentPage == @collection.pagination.pagesTotal
                $(ev.currentTarget).hide()

    render: ->
        ctx =
            levels: @collection
            templates:
                item: @templates.item

        @$el.html @templates.list ctx

        @$list = @$el.find '.media-list'

        return @


class views.LevelView extends View
    template: JST.level

    initialize: (options) ->
        @levelId = options.levelId

        super options

    render: ->
        ctx =
            level:
                id: @levelId

        @$el.html @template ctx

        @$levelEdit = @$el.find '#level-edit'

        level = new castle.models.Level {id: @levelId}

        level.fetchWithoutData success: =>
            if @children.levelEdit?
                @children.levelEdit.remove()

            @children.levelEdit = (new views.LevelEditView {model: level, app: @app, parent: @}).appendTo @$levelEdit

        return @

    update: (options) ->
        @levelId = options.levelId

        @render()


class views.LevelEditView extends View
    template: JST.level_edit

    events:
        'click #save-btn': (ev) ->
            tags = @$tags.val()
            flags = @$flags.val()

            owner = @model.get('owner') || {}

            owner_displayname = owner.displayname || owner.username

            data =
                name: @$name.val()
                description: @$description.val()
                gameplay: @$gameplay.val()
                visibility: @$visibility.val()
                tags: if tags != '' then (_.str.trim(tag) for tag in tags.split(',')) else []
                flags: if flags != '' then (_.str.trim(flag) for flag in flags.split(',')) else []

            if @$thumbnailData
                data['imageData'] = @$thumbnailData

            if @$dataLevel
                data['data'] = @$dataLevel

            if @$selectedOwnerId
                data['owner_id'] = @$selectedOwnerId;
                data['owner'] = { id : @$selectedOwnerId, username : @$selectedOwnerName, email: @$selectedOwnerEmail }
                owner_displayname = @$selectedOwnerDisplayname || @$selectedOwnerName

            data['owner_display_name'] = owner_displayname

            @app.eventBus.trigger 'notification', 'warning', null, 'Updating level...', null

            @model.save data, success: (model, response) =>
                @app.eventBus.trigger 'levels.model.update', @model
                @app.eventBus.trigger 'notification', 'success', null, 'Level has been updated.'
                @rerender()

        'click #cancel-btn': (ev) ->
            @app.router.navigate 'levels', {trigger: true}

        'click #delete-btn': (ev) ->
            ev.preventDefault()

            @app.eventBus.trigger 'notification', 'warning', null, 'Removing level...', null

            @model.destroy success: (model, response) =>
                @app.eventBus.trigger 'levels.model.destroy', @model
                @app.eventBus.trigger 'notification', 'success', null, 'Level has been removed.'
                @app.router.navigate 'levels', {trigger: true}

    render: ->
        ctx =
            level: @model

        @$el.html @template ctx

        @$name = @$el.find '#name'
        @$description = @$el.find '#description'
        @$gameplay = @$el.find '#gameplay'
        @$visibility = @$el.find '#visibility'
        @$tags = @$el.find '#tags'
        @$flags = @$el.find '#flags'
        @$file = @$el.find '#level-file'
        
        self = @

        @$owner = @$el.find '#level-owner'
        @$owner.autocomplete({
            minLength : 2
            appendTo  : @$el
            select : (event, ui) =>
                self.$selectedOwnerId = ui.item.id
                self.$selectedOwnerName = ui.item.label
                self.$selectedOwnerEmail = ui.item.email
                self.$selectedOwnerDisplayname = ui.item.displayname

            source: ( request, response ) =>

                access_token = @app.context.get 'access_token'

                $.getJSON "#{@app.config.API_URL}/v1/users?username=" + request.term, {access_token: access_token}, (data) ->
                            response $.map data.users, ( user ) =>
                                return { label: user.username, value: user.username , id : user.id , email: user.email, displayname: user.displayname}

            }).autocomplete('widget').css('z-index', 2000);


        @$file.bind 'change', (event) ->
            reader = new FileReader();

            fileName = event.target.files[0].name

            reader.onload = (readerEvent) ->

                if readerEvent.target.readyState == FileReader.DONE

                    fileBinaryString = reader.result
                    arrayBuf = new Array(fileBinaryString.length)
              
                    for i in [0...fileBinaryString.length]
                        arrayBuf[i] = fileBinaryString.charCodeAt(i) & 0xff

                    gzip = new Zlib.Gzip(arrayBuf, { filename : fileName } )
                    compressed = gzip.compress()
                    base64String = btoa(String.fromCharCode.apply(null, compressed))

                    self.$dataLevel = base64String

            reader.readAsBinaryString( event.target.files[0] )

        @$thumbnailFile = @$el.find '#level-thumbnail-file'
        
        @$thumbnailFile.bind 'change', (event) ->
            reader = new FileReader();

            reader.onload = ->
                self.$thumbnailData = reader.result.match(/,(.*)$/)[1]

            reader.readAsDataURL( event.target.files[0] ) 

        return @

class views.NewLevelDialog extends View
    template: JST.level_new_dialog

    initialize: (options) ->
        @collection = options.collection || []
        super options

    events:
        'click #level-new-close-btn': (ev) ->
            $('#new-level-btn').prop 'disabled', false
            @remove()

        'click #level-new-create-btn': (ev) ->

            ev.preventDefault()

            @$alert.fadeOut()


            @app.eventBus.trigger 'showInfo', 'warning', null, 'Creating level...', null


            visibility = 'private'

            $('#level-visibility  .btn.active').each (idx, selectionObj) ->
                visibility = selectionObj.value


            name        = @$name.val()
            description = @$description.val()
            gameplay    = @$gameplay.val()
            tags        = @$tags.val()
            flags       = @$flags.val()

            if name == '' 
                return @alert 'Name cannot be empty'

            levelForm = $('#new-level-form')

            access_token = @app.context.get 'access_token'

            serialLevelUploads = []
            self = @

            serialSetter = (data,levelName, idx, count) ->
                return (cb) ->
                        self.app.eventBus.trigger 'showInfo', 'warning', null, "start sending level #{idx} of #{count} name : #{levelName}...", null

                        $.ajax "#{self.app.config.API_URL}/v1/levels", {
                            type: 'POST'
                            data: JSON.stringify data
                            contentType: 'application/json; charset=utf-8'
                            dataType: 'json'
                            beforeSend: (xhr) -> xhr.setRequestHeader 'X-Castle-Auth', access_token
                            success: (responseData) =>
                                self.app.eventBus.trigger 'showInfo', 'warning', null, "end sending level #{idx} of #{count} name : #{levelName}...", null
                                cb null, [responseData, data]
                            error: (jqXHR) =>
                                try
                                    data = JSON.parse jqXHR.responseText
                                    errorType = data.error.type

                                    console.log 'Failed to create new level: ', jqXHR
                                catch e
                                    console.log 'Failed to parse response: ', jqXHR

                                self.alert 'Unexpected error occured. Please refresh the page and try again.'
                                cb jqXHR, null

                            complete: =>
                                self.$submit.prop 'disabled', false
                        }

            uploadCount = self.levelDataUploadList.length

            for value, key in self.levelDataUploadList

                levelName = value[0]
                levelData = value[1].data
                levelImage = value[1].image
                levelMeta = value[1].meta || {}

                castleId = levelName



                @app.eventBus.trigger 'showInfo', 'warning', null, "start gziping level #{levelName}...", null

                arrayBuf = new Array(levelData.length)
              
                for i in [0...levelData.length]
                    arrayBuf[i] = levelData.charCodeAt(i) & 0xff

                gzip = new Zlib.Gzip(arrayBuf, { filename : levelName } )
                compressed = gzip.compress()
                levelDataBase64 = btoa(String.fromCharCode.apply(null, compressed))


                flags = levelMeta.flags ? flags
                tags  = levelMeta.tags ? tags

                data =
                    castle_id : levelMeta.castleId ? castleId
                    name          : levelMeta.name ? name 
                    description   : levelMeta.description ? description 
                    gameplay      : levelMeta.gameplay ? gameplay 
                    tags: if tags != '' then (_.str.trim(tag) for tag in tags.split(',')) else []
                    flags: if flags != '' then (_.str.trim(flag) for flag in flags.split(',')) else []
                    visibility : levelMeta.visibility ? visibility
                    data : levelDataBase64

                if self.$selectedOwnerId
                    data['owner_id'] = self.$selectedOwnerId
                    data['owner_display_name'] = self.$selectedOwnerDisplayname
                else
                    if levelMeta.owner?
                        data['owner_id'] = levelMeta.owner.id
                        data['owner_display_name'] = levelMeta.owner.displayname
                    else
                        return @alert 'Can not find owner: ' + levelMeta.ownerUsername

                    
                if levelImage
                    data['imageData'] = levelImage


                if uploadCount > 1 and not levelMeta.name
                    data.name        = name + "-#{levelName}"
                    data.description = description + "[ imported form #{levelName}.xml ]"

                serialLevelUploads.push serialSetter data, levelName, key, uploadCount 


            async.series serialLevelUploads, (err, dataLevelResults) ->

                self.app.router.navigate 'levels', {trigger: true}

                for dataEntry in dataLevelResults

                    data = dataEntry[0]
                    requestedData = dataEntry[1]

                    data.level.name = requestedData.name
                    data.level.description = requestedData.description

                    if self.$selectedOwnerName
                        data.level.owner.username = self.$selectedOwnerName

                    if self.$selectedOwnerEmail
                        data.level.owner.email = self.$selectedOwnerEmail

                    if self.$selectedOwnerDisplayname
                        data.level.owner.display_name = self.$selectedOwnerDisplayname

                    self.collection.add data.level
                    $('#new-level-btn').prop 'disabled', false
                    self.app.eventBus.trigger 'hideInfo'

                    #@app.eventBus.trigger 'notification', 'success', null, 'Level has been created.'
                    self.remove()

            #@app.eventBus.trigger 'notification', 'warning', null, 'Creating level...', null


    render: ->
        @$el.html @template {}

        @$alert    = @$el.find '#level-new-alert'
        @$submit   = @$el.find '#level-new-create-btn'

        #@$submit.prop 'disabled', true

        @$name = @$el.find '#level-name'
        @$description = @$el.find '#level-description'
        @$gameplay = @$el.find '#level-gameplay'
        @$visibility = @$el.find '#level-visibility'
        @$tags = @$el.find '#level-tags'
        @$flags = @$el.find '#level-flags'
        @$file = @$el.find '#level-file'
        
        self = @

        @$owner = @$el.find '#level-owner'
        @$owner.autocomplete({
            minLength : 2
            appendTo  : @$el
            select : (event, ui) =>
                self.$selectedOwnerId = ui.item.id
                self.$selectedOwnerName = ui.item.label
                self.$selectedOwnerEmail = ui.item.email
                self.$selectedDisplayname = ui.item.displayname
            source: ( request, response ) =>

                access_token = @app.context.get 'access_token'

                $.getJSON "#{@app.config.API_URL}/v1/users?username=" + request.term, {access_token: access_token}, (data) ->
                            response $.map data.users, ( user ) =>
                                return { label: user.username, value: user.username , id : user.id , email: user.email, displayname: user.displayname}

            }).autocomplete('widget').css('z-index', 2000);
        

        @$file.bind 'change', (event) ->

            fileReaders = []

            serialSetter = (file) ->
                return (cb) ->
                    reader = new FileReader();
                    reader.onload = (readerEvent) ->
                            if readerEvent.target.readyState == FileReader.DONE
                                cb null, [reader, file]

                    if file.type.match('image.*')
                        reader.readAsDataURL( file )
                    else if file.type.match('.*xml')
                        reader.readAsBinaryString( file )


            for file in event.target.files 
                fileReaders.push serialSetter file

            async.series fileReaders, (err, fileReadersResult) ->
                levelDataUploadPairs = {}

                for fileEntry in fileReadersResult
                    reader   = fileEntry[0]
                    file     = fileEntry[1]
                    fileName = file.name
                    fileNameParts =  fileName.split('.')

                    if fileNameParts.length == 0
                        continue

                    fileNameNoExtPostfix = fileNameParts[0].substr(-1)
                    fileNameNoExt        = fileNameParts[0].slice(0,-1)

                    if not levelDataUploadPairs[fileNameNoExt]
                        levelDataUploadPairs[fileNameNoExt] = {}

                    if file.type.match('image.*')
                        levelDataUploadPairs[fileNameNoExt].image = reader.result.match(/,(.*)$/)[1]
                    else
                        if fileNameNoExtPostfix == "d"
                            levelDataUploadPairs[fileNameNoExt].data = reader.result
                        else
                            if fileNameNoExtPostfix == "m"
                                meta = {}

                                if reader.result?

                                    levelMetaObj = $.parseXML(reader.result)
                                    levelMetaObj = $(levelMetaObj)

                                    IdObj = levelMetaObj.find("Id")
                                    meta.objId = IdObj.text() if IdObj?

                                    OwnerIdObj = levelMetaObj.find("OwnerId")
                                    meta.ownerId = OwnerObj.text() if OwnerObj?

                                    meta.owner = null

                                    OwnerNameObj = levelMetaObj.find("Owner")
                                    meta.ownerUsername = OwnerNameObj.text() if OwnerNameObj?

                                    if meta.ownerUsername
                                        $.getJSON "#{self.app.config.API_URL}/v1/users?username=" + meta.ownerUsername, {access_token: self.app.context.get 'access_token'}, (data) ->
                                            meta.owner = data.users[0]
                                            self.$owner.val(meta.owner.username || "")

                                    castleIdObj = levelMetaObj.find("CastleId")
                                    meta.castleId    = castleIdObj.text() if castleIdObj?

                                    DescriptionObj = levelMetaObj.find("Description")
                                    meta.description    = DescriptionObj.text() if DescriptionObj?

                                    NameObj = levelMetaObj.find("Name")
                                    meta.name    = NameObj.text() if NameObj?

                                    GameplayObj = levelMetaObj.find("Gameplay")
                                    meta.gameplay    = GameplayObj.text() if GameplayObj?

                                    VisibilityObj = levelMetaObj.find("Visibility")
                                    meta.visibility    = VisibilityObj.text() if VisibilityObj?

                                    $('#level-visibility  .btn.active').each (idx, selectionObj) ->
                                        $(selectionObj).removeClass("active")

                                    $('#level-visibility  .btn').each (idx, selectionObj) ->
                                        if meta.visibility == selectionObj.value
                                            $(selectionObj).addClass("active")

                                    meta.tags = []

                                    levelMetaObj.find("Tags").find('string').each (index, item) ->
                                        meta.tags.push( $(this).text() )

                                    meta.tags = meta.tags.join(',')

                                    meta.flags = []

                                    levelMetaObj.find("Flags").find('string').each (index, item) ->
                                        meta.flags.push( $(this).text() )

                                    meta.flags = meta.flags.join(',')

                                    CommentsObj = levelMetaObj.find("Comments")
                                    meta.comments = CommentsObj.text() if CommentsObj?

                                    PlaysObj = levelMetaObj.find("Plays")
                                    meta.plays = PlaysObj.text() if PlaysObj?

                                    LikesObj = levelMetaObj.find("Likes")
                                    meta.likes    = LikesObj.text() if LikesObj?

                                    DownloadsObj = levelMetaObj.find("Downloads")
                                    downloads = DownloadsObj.text() if DownloadsObj?

                                    meta.PanicsObj = levelMetaObj.find("Panics")
                                    meta.Panics = PanicsObj.text() if PanicsObj?

                                    levelDataUploadPairs[fileNameNoExt].meta = meta

                self.levelDataUploadList = []

                for levelName, levelData of levelDataUploadPairs
                    if not levelData.data
                        continue
                    self.levelDataUploadList.push([levelName,levelData])

                if self.levelDataUploadList.length > 0 and self.levelDataUploadList[0][1].meta?
                    meta = self.levelDataUploadList[0][1].meta
                    self.$name.val(meta.name)
                    self.$description.val(meta.description)
                    self.$gameplay.val(meta.gameplay)
                    #self.$visibility.val(meta.visibility)
                    self.$tags.val(meta.tags)
                    self.$flags.val(meta.flags)

                if self.levelDataUploadList.length != 0
                    self.$submit.prop 'disabled', false


        self.$submit.attr("disabled", "true");

        return @

    alert: (message) ->
        @$alert.html message
        @$alert.fadeIn()

        return @

    show: ->
        ($ '#root').append @$el
        @$el.show()
