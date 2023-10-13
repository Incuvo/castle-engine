module.exports.roundToSignificantNumbers = (value, significantNumber) ->
    if(significantNumber == 0)
        return 0

    cuttedDecimals = 0
    boundValue = Math.pow(10, significantNumber)

    if(value >= 0)
        while(value > boundValue)
            value /= 10.0
            cuttedDecimals += 1

    else
        while(value > -boundValue)
            value /= 10.0
            cuttedDecimals += 1

    return parseInt(value) * Math.pow(10, cuttedDecimals)

module.exports.roundNumber = (value) ->
    x = parseInt value
    y = value - 0.5
    z = parseInt y

    if x == z and x == y
        if x % 2 == 0
            return x
        else
            return x + 1

    else if x == z
        if y >= 0
            return x + 1
        else
            return x

    else
        return x