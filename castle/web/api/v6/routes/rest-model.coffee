# Defines API endpoints.
util = require("util")
crypto = require 'crypto'
mongoose = require 'mongoose'
u = require 'underscore'
async = require 'async'

mm = require '../db/mongodb/models'
mw = require '../middleware'
ex = require '../../exceptions'
mv = require '../model-views'
moment   = require 'moment'
stemmer = require '../../../util/stemmer'
hashids  = require 'hashids'
randutil = require '../../../util/rand'
jstoxml   = require '../../../util/jstoxml'


ValidationError = mongoose.Document.ValidationError
ObjectId = mongoose.Types.ObjectId



exports.getSchemeModel = (modelName) ->

    return (req, res, next) ->

        model = mm[req.params.modelName]

        if not model
            return next new ex.NotFound userId

        schema = {}

        for field_name, raw_field_def of model.schema.paths

            field_def = {}

            isArray = false

            defaultValue = raw_field_def.defaultValue || ""

            field_def.type = raw_field_def.instance

            if raw_field_def['caster']
                isArray = true
                field_def.type = raw_field_def['caster']?.instance || "String"


            field_def.isArray = isArray
            field_def.defaultValue = defaultValue

            if raw_field_def.enumValues
                field_def.enumValues = raw_field_def.enumValues

            schema[field_name] = field_def

        res.json
            schema: schema


exports.restGenericModel = (pageSize = 32) ->

    return {

        list: (req, res, next) ->

            model = mm[ req.params.modelName ]

            if not model
                return next new ex.NotFound "Model #{modelName}"


            page    = if req.query.page? then parseInt(req.query.page) else 1
            perPage = if req.query.per_page? then parseInt(req.query.per_page) else pageSize
            begin   = perPage*(page - 1)

            filtersQuery = []

            nameQuery         = if req.query.name? then

            for filter in req.query.filters || []
                if req.query[filter]
                    filterDef = {}
                    filterDef[filter] = {'$regex': req.query[filter]}
                    filtersQuery.push filterDef

            #console.log "filters %j",filtersQuery

            sortBy = if req.query.sortBy then req.query.sortBy else '-created'

            now = Date.now()

            query = {}

            if filtersQuery.length > 0
                query =
                    '$and': filtersQuery


            model.find(query).count (err, total) ->

                if err?
                    return next err

                if req.query.populate
                    q = model.find(query).populate(req.query.populate).skip(begin).limit(perPage).sort(sortBy)
                else
                    q = model.find(query).skip(begin).limit(perPage).sort(sortBy)

                q.exec query, (err, items) ->

                    if err?
                        return next err


                    #itemsOut = []

                    #for authObj in items
                    #    authObj = JSON.parse(JSON.stringify(authObj));
                    #    authObj.id = authObj._id
                    #    itemsOut.push authObj

                    res.json
                        page: page
                        per_page: perPage
                        total: total
                        items:items


        create: (req, res, next) ->

            model = mm[ req.params.modelName ]

            if not model
                return next new ex.NotFound "Model #{modelName}"



            dbProps = {}
            dbProps = u.extend(dbProps, req.body)

            dbProps.created = Date.now()

            model.create dbProps, (err, newConfig) ->

                if err?
                    return next err

                res.status(201).json {
                }

        read: (req, res, next) ->

            model = mm[ req.params.modelName ]

            if not model
                return next new ex.NotFound "Model #{modelName}"

            ###
            # HERE TO DO RANDOM item get
            ###

            itemId = if req.params.id == 'me' then req.castle.user._id else req.params.id

            model.findById itemId, (err, doc) ->

                if not doc?
                    util.log "[Castle API] rest-model have not found itemId object: #{itemId}"
                    return next new ex.NotFound userId

                res.json
                    item: item

        update: (req, res, next) ->

            model = mm[ req.params.modelName ]

            if not model
                return next new ex.NotFound "Model #{modelName}"


            model.findById req.params.id, (err, updateObj) ->

                if err?
                    return next err

                if not updateObj
                    return next new ex.NotFound req.params.id

                if req.body.created
                    delete req.body.created

                updateObj = u.extend(updateObj, req.body)

                updateObj.save (err, updatedObj) ->

                    if err
                        return next err

                    res.json
                        item: updatedObj

        delete: (req, res, next) ->

            model = mm[ req.params.modelName ]

            if not model
                return next new ex.NotFound "Model #{modelName}"


            model.findOne { _id: req.params.id }, (err, foundObj) ->

                if err?
                    return next err

                if not foundObj?
                    return next new ex.NotFound req.params.id

                foundObj.remove (err, doc) ->

                    if err?
                        return next err

                    res.status(200).json {}


        }
