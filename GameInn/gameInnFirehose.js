module.exports = class GameInnFirehose {
    constructor(accessKeyId, secretAccessKey, region, streamName) {
        this.AWS = require('aws-sdk');
        this.AWS.config.update({accessKeyId: accessKeyId, secretAccessKey: secretAccessKey, region: region});
        this.Firehose = new this.AWS.Firehose();
        this.streamName = streamName;
    }

    sendEvent(eventName, eventData, callback) {
        var event = {
            DeliveryStreamName: this.streamName,
            Record: {
                Data: new Buffer(JSON.stringify({eventName: eventName, data: eventData})) || 'STRING_VALUE'
            }
        };

        this.Firehose.putRecord(event, callback);
    }
}