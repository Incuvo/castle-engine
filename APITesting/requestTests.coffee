chai = require 'chai'
chaiHttp = require('chai-http')
chai.use(chaiHttp)
expect = chai.expect

requestTest = true
requestHost = "http://localhost"

if(requestTest)
    describe 'REQUEST TEST for ' + requestHost, ->
        it 'server heartbeat', (done) ->
            chai.request(requestHost).get('/_internal/server/health/k19wi180a9ed9rdl').end (err, res) ->
                expect(err).to.be.null
                expect(res).to.have.status(200)
                done()
            return

        it 'getServerTime', (done)  ->
            chai.request(requestHost).get('/v1/getServerTime').set('X-Castle-Auth','oxGCE1Hypile7yys3sUJmlMOGXjcAswc:NQnR2jVQTOTHmmNcK9c6xWmDIc5dqq00').end (err, res) ->
                expect(err).to.be.null
                expect(res).to.have.status(200)
                expect(res.body).to.be.a('object')
                expect(res.body).to.have.all.keys(['ver', 'ts'])
                done()
            return

        it 'getBalconomy', (done) ->
            chai.request(requestHost).get('/v1/getBalconomy').query({'version': 0.01}).set('X-Castle-Auth','oxGCE1Hypile7yys3sUJmlMOGXjcAswc:NQnR2jVQTOTHmmNcK9c6xWmDIc5dqq00').end (err, res) ->
                expect(err).to.be.null
                expect(res).to.have.status(200)
                expect(res.body).to.be.a('object')
                expect(res.body.balconomy).to.be.a('object')
                expect(res.body.balconomy).to.contain.all.keys(['version', 'balance', 'config', 'economy'])
                done()
            return