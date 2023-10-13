jStat = require('jStat').jStat

randomRange = (low, high) ->
    return Math.floor(Math.random() * (high - low) + low)

findBestBucketsNumber = (length, desiredCount) ->

    # console.log 'Find best bucket: ' + length + ', ' + desiredCount

    if length < 10
        return length
    
    miesci = Math.floor( length / desiredCount )
    roznica = length - desiredCount
    buckets = 10 # initial

    while buckets > 1

        reszta = length % buckets
        if ( (length - reszta) >= desiredCount ) # mozna spokojnie ciachac do rownego bez reszty
            # console.log 'returning ' + buckets
            return buckets
        buckets -= 1
    
    # nie dalo sie znalezc ponizej dziesiatki
    
    buckets = 10 # initial

    while buckets < 20

        reszta = length % buckets
        if ( (length - reszta) >= desiredCount ) # mozna spokojnie ciachac do rownego bez reszty
            # console.log 'returning ' + buckets
            return buckets
        buckets += 1

    # znowu sie nie udalo
    
    return 1

randomGammaHist = (gamma_size, gamma_scale, buckets, bucket_size, sample_size) ->
    samples = new Array(sample_size)
    histogram = new Array(buckets)
    histogram.fill 0
    # get random gamma sample for _samples_ times
    i = 0
    while i < sample_size
        # getting sample also check if not overboard
        while (samples[i] = jStat.gamma.sample(gamma_size, gamma_scale)) >= buckets
        # retry because we went off the buckets (very unlikely but gamma is infinite)
            samples[i] = jStat.gamma.sample(gamma_size, gamma_scale)
        #fill histogram
        index = Math.floor(samples[i])
        while (histogram[index] == bucket_size)
            index += 1          #safety - if bucket full, go for next bucket
            if (index > buckets)
                index = 0       # start over if out of bounds
        histogram[index] += 1
        i += 1
    return histogram  # array for example: [6,3,0,1,0]

module.exports.randomRange = randomRange

module.exports.randomFloatRange = (low, high) ->
    return Math.random() * (high - low) + low

module.exports.chooseWithChance = (weights) ->

    weightCount     = weights.length
    sumOfChances = 0

    for weight in weights
        sumOfChances += weight


    rndVal = randomRange(0, sumOfChances)

    while (rndVal -= weights[weightCount - 1]) > 0
        weightCount--
        sumOfChances -= weights[weightCount - 1]

    return weightCount - 1


module.exports.arrayShuffle = (a) ->
    i = a.length
    while --i > 0
        j = ~~(Math.random() * (i + 1))
        t = a[j]
        a[j] = a[i]
        a[i] = t

    return a


module.exports.randomStringNumber = (length) ->
    string = ''
    i = 0
    while i < length
        i++
        rnum = Math.floor(Math.random() * 10)
        string += rnum

    return string

module.exports.randomGammaHist = randomGammaHist


module.exports.pickRandomGammaUsers = (user_ids, desiredCount) ->

    if ( user_ids.length == desiredCount )
        return user_ids

    buckets_nr = findBestBucketsNumber(user_ids.length, desiredCount)
   
    #  buckets_nr
    # and recalculate bucket size
    bucket_size = Math.max( Math.floor(user_ids.length / buckets_nr), 1)
    picked_user_ids = new Array()

    histogram = randomGammaHist( 1, 1, buckets_nr, bucket_size, desiredCount )
    # console.log 'Users wanted: ' + desiredCount + ', got: ' + user_ids.length + ', buckets count: ' + buckets_nr + ', bucket new size: ' + bucket_size + ', histogram: ' + histogram

    # get histogram[i] first users in every bucket.
    bucket_number = 0
    while bucket_number < histogram.length
        if (histogram[bucket_number])
            
            # console.log 'Picking ' + histogram[bucket_number] + ' users from bucket nr ' + bucket_number + ' (' + bucket_size + ' users)'
            users_to_pick_in_this_bucket = histogram[bucket_number]
            index = 0
            while index < users_to_pick_in_this_bucket
                pick_nr = Math.max( (index + bucket_size * bucket_number), (picked_user_ids.length) ) # bucket overconsumption protection
                picked_user_ids.push( user_ids[ pick_nr ] )
                index += 1
        bucket_number += 1

    # console.log 'Picked users length: ' + picked_user_ids.length
    return picked_user_ids


