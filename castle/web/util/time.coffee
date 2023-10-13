module.exports.clientTimeformatToTimestamp = (datestring) ->
#datestring has format: 25/11/2016 13:38:09
    dateChunks = datestring.split /\/| |:/
    day = dateChunks[0]
    month = dateChunks[1] - 1
    year = dateChunks[2]
    hour = dateChunks[3]
    minutes = dateChunks[4]
    seconds = dateChunks[5]
    date = new Date year, month, day, hour, minutes, seconds, 0

    return date.getTime()

module.exports.timestampToClientTimeformat = (ts) ->
    date = new Date(ts)
    day = ('0' + date.getDate()).slice(-2)
    month = ('0' + (date.getMonth()+1)).slice(-2)
    year = date.getFullYear()
    hour = ('0' + date.getHours()).slice(-2)
    minutes = ('0' + date.getMinutes()).slice(-2)
    seconds = ('0' + date.getSeconds()).slice(-2)

    return day + '/' + month + '/' + year + ' ' + hour + ':' + minutes + ':' + seconds