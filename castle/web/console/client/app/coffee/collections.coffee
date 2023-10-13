castle.collections = collections = {}


# Cache previous results if possible
PaginatedCollection = class collections.PaginatedCollection extends Backbone.Collection
    resource: 'objects'

    initialize: (models, options) ->
        super models, options

        @pagination =
            currentPage: options?.currentPage ? 1
            perPage: options?.perPage ? 15

        @search = options?.search ? {}
        @populate = options?.populate ? []

    parse: (response, xhr) ->
        @pagination.currentPage = response.page
        @pagination.perPage = response.per_page
        @pagination.itemsTotal = response.total
        @pagination.pagesTotal = Math.ceil(@pagination.itemsTotal/@pagination.perPage)

        return response[@resource]

    fetch: (options={}) ->
        @trigger('fetching')

        success = options.success

        options.success = (response) =>
            @trigger('fetched')

            success(response) if success?

        options.data = options.data ? {}

        options.data = _.extend options.data, {
            page: @pagination.currentPage
            per_page: @pagination.perPage
            cacheInvalidateList : options.cacheInvalidateList
        }, @search, {
            populate: @populate.join ',' if @populate.length
        }

        super options

    url: ->
        return castle.config.API_URL + @ROOT_URL

    page: (value, options) ->
        switch value
            when 'next'
                @pagination.currentPage = (@pagination.currentPage % @pagination.pagesTotal) + 1
            when 'previous'
                @pagination.currentPage = (@pagination.currentPage - 1) or @pagination.pagesTotal
            else
                @pagination.currentPage = value

        @fetch options

        return @


class collections.UsersCollection extends PaginatedCollection
    ROOT_URL: '/v1/users'
    resource: 'users'
    model: castle.models.User


class collections.LevelsCollection extends PaginatedCollection
    ROOT_URL: '/v1/levels'
    resource: 'levels'
    model: castle.models.Level
