awssum    = require 'awssum'
mongoose  = require("mongoose")
GridStore = mongoose.mongo.GridStore
Grid      = mongoose.mongo.Grid
ObjectID  = mongoose.mongo.BSONPure.ObjectID


amazon = awssum.load 'amazon/amazon'
AWS_S3 = awssum.load('amazon/s3').S3


exports.CloudStorage = class CloudStorage
    constructor: (options) ->
        @options = options || {}

    get: (resource, cb) ->

    put: (resource, cb) ->

    getURL: (resource) ->


exports.S3Storage = class S3Storage extends CloudStorage
    get: (resource, cb) ->
        try
            s3 = new AWS_S3 {
                accessKeyId: @options.aws.key
                secretAccessKey: @options.aws.secret
                region: @options.aws.region
            }

            s3.GetObject {
                BucketName: resource.bucket
                ObjectName: resource.name
            }, (err, response) ->
                if err?
                    return cb err, null

                return cb null, response.Body
        catch error
            return cb error, null


    put: (resource, cb) ->
        try
            s3 = new AWS_S3 {
                accessKeyId: @options.aws.key
                secretAccessKey: @options.aws.secret
                region: @options.aws.region
            }

            s3.PutObject {
                BucketName: resource.bucket
                ObjectName: resource.name
                ContentType: resource.mime
                Acl: 'public-read'
                MetaData:
                    created: Date.now() + ''
                ContentLength: resource.length
                ContentEncoding: resource.encoding
                Body: resource.data
            }, (err, response) =>
                return cb err, response
        catch err
            return cb err, null

    getURL: (resource, ctx) ->
        return "#{resource.bucket}.s3.amazonaws.com/#{resource.name}"



exports.MongoGridFSStorage = class MongoGridFSStorage extends CloudStorage

    get: (resource, cb) ->
        @getStore resource, (err, store) ->
            store.read  (err, data) ->
                cb null, data

    getStore: (resource, cb) ->
        try
            if resource and resource.name and resource.bucket
                filePath = @getURL resource, null
            else
                filePath = resource

            mongoose.connection.db.collection 'gfs.files', (err, collection) ->

                if err
                    return cb err, null

                 queryOptions =
                    limit: 1
                    sort : [ ['uploadDate' , -1] ]
                    fields:
                        _id : 1
                        filename : 1,

                collection.find { filename:filePath }, queryOptions, (err, cursor) ->

                    if err
                        return cb err, null

                    cursor.nextObject (err, file) ->

                        if err
                            return cb err, null

                        if not file
                            return cb null, null

                        gs = new GridStore mongoose.connection.db, file._id, file.filename, "r", { root : 'gfs' }

                        gs.open (err, store) ->
                                cb err, store
        catch error
            return cb error, null


    put: (resource, cb) ->
        try
            options =
                root :'gfs'
                metadata : {}

            filePath = @getURL resource, null

            id  = new ObjectID()

            gs = new GridStore mongoose.connection.db, id, filePath, "w", options

            gs.open (err, store) ->

                if err
                    return cb err, null

                store.write resource.data, (err, store) ->
                    store.close (err, result) ->
                        cb err, result
        catch err
            return cb err, null

    getURL: (resource, ctx) ->
        return "castle-api.castle.com/gfs/#{resource.bucket}/#{resource.name}"
