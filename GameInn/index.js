var GameInn = {};
var GameInnFirehose = null;
var GameInnS3 = null;

GameInn.Init = function(accessKeyId, secretAccessKey, region, streamName, bucketName) {
    var firehoseClass = new require('./gameInnFirehose');
    GameInnFirehose = new firehoseClass(accessKeyId, secretAccessKey, region, streamName);

    var s3Class = new require("./gameInnS3")
    GameInnS3 = new s3Class(accessKeyId, secretAccessKey, region, bucketName);
}

GameInn.SendEvent = function(eventName, eventData, callback) {
    if(GameInnFirehose == null) {
        callback("No GameInn ready", null);
    } else {
        GameInnFirehose.sendEvent(eventName, eventData, callback);
    }
}

GameInn.SendFile = function(fileName, data, callback) {
    if(GameInnS3 == null) {
        callback("No GameInn ready", null);
    } else {
        GameInnS3.sendFile(fileName, data, callback);
    }
}

module.exports = GameInn;