module.exports = class GameInnS3 {
    constructor(accessKeyId, secretAccessKey, region, bucketName) {
        this.AWS = require('aws-sdk');
        this.AWS.config.update({accessKeyId: accessKeyId, secretAccessKey: secretAccessKey, region: region});
        this.S3 = new this.AWS.S3();
        this.bucketName = bucketName;
    }

    sendFile(fileName, data, callback) {
        var base64data = new Buffer(JSON.stringify(data), 'binary');

        this.S3.putObject({
            Bucket: this.bucketName,
            Key: fileName,
            Body: base64data,
            ACL: 'public-read'
          }, callback);
    }
}