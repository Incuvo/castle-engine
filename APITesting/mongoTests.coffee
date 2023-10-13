chai = require 'chai'
chaiHttp = require('chai-http')
chai.use(chaiHttp)
expect = chai.expect
mm = require './mongodb/models'

mongoTest = true
apiTest = true

mongoose = require 'mongoose'

db = mongoose.connect "mongodb://localhost:27017/castle-staging",
    server:
        #readPreference : 'secondary'
        auto_reconnect: true
        poolSize: 20
        socketOptions:
            keepAlive : 1

if(mongoTest)    
    describe 'MONGO TEST', ->
        it 'Any Players exist?', (done) ->
            mm.UserProfile.find().exec (err, doc) ->
                expect(err).to.be.null
                expect(doc).to.not.be.empty
                done()

        it 'Is Balconomy exist?', (done) ->
            mm.Balconomy.find().sort({version:-1}).exec (err, doc) ->
                expect(err).to.be.null
                expect(doc).to.not.be.empty
                done()

        it 'Is Castle Definition exist?', (done) ->
            mm.DefinitionCastle.find().exec (err, doc) ->
                expect(err).to.be.null
                expect(doc).to.not.be.empty
                done()

#        it 'Is User "castle_admin" exist?', (done) ->
#            mm.UserProfile.findOne({username:'castle_admin'}).exec (err, doc) ->
#                expect(err).to.be.null
#                expect(doc).to.exist
#                done()

#        it 'Is Tutorial Enemies exist?', (done) ->
#            mm.UserProfile.findOne({username:'lord_jeffrey'}).exec (err, doc) ->
#                expect(err).to.be.null
#                expect(doc).to.exist
#

#            mm.UserProfile.findOne({username:'lord_greyson'}).exec (err, doc) ->
#                expect(err).to.be.null
#                expect(doc).to.exist

if(apiTest)
    mongoose = require 'mongoose'

    describe 'API TEST', ->
        it 'UserProfile.getEnemiesInRange works?', ->
            mm.UserProfile.getEnemiesInRange 0, [], (err, doc) ->
                expect(err).to.be.null
                expect(doc).to.exist
                expect(doc).to.be.a('array')

        it 'Balconomy.getLastVersion works?', ->
            mm.Balconomy.getLastVersion (doc) ->
                expect(doc).to.be.a('object')