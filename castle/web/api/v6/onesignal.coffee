OneSignalAppId = "ca017411-217c-488c-885b-ca647da0bb1d"
RESTAPIKey = "YWQ0ZmRkYTktN2I0ZS00ZjY0LWFmMzktNWVlNWJmYTNiOWVk"
ApiVersion = "v1"

https = require 'https'
util = require 'util'

send = (data, task, method) ->

    headers =
        "Content-Type": "application/json",
        "Authorization": "Basic " + RESTAPIKey

    options =
        host: "onesignal.com",
        port: 443,
        path: "/api/" + ApiVersion + "/" + task,
        method: method,
        headers: headers

    data["app_id"] = OneSignalAppId

    req = https.request options, (res) ->
        res.on 'data', (data) ->
        #      util.log "Response:"
        #      util.log data

    req.write JSON.stringify data
    req.end()

    req.on 'error', (err) ->
        util.log "[ERROR] When sending onesignal request " + err


exports.simpleNotification = (message) ->

    data =
        contents:
            en: message
            included_segments: ["All"]

    send data, "notifications", "POST"



exports.simpleUserNotification = (message, userId) ->

    data =
        contents:
            en: message
        filters: [
            {field: "tag", key: "UserObjectId", relation: "=", value: userId}
        ]

    send data, "notifications", "POST"
