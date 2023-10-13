#COMPARES PROFILE AND SHOWS RESULT ABOUT IT
VERBOSE = false

logTitle = (title) ->
    if not VERBOSE
        return
    util.log ' '
    util.log '==> ' + title

logGood = (generalMessage, valueBoth = '') ->
    if not VERBOSE
        return
    str = '[o] ' + generalMessage
    if valueBoth != ''
        str += '. Value for both: ' + valueBoth
    util.log str

logBad = (generalMessage, valueA, valueB) ->
    util.log '[x] ' + generalMessage + '. Client: ' + valueA + ', Server: ' + valueB

logSummary = (title, errors) ->
    if errors > 0
        util.log '==> [x][x][x] ' + errors + ' errors occured at ' + title
    else
        util.log '==> [o][o][o] finished at ' + title

    util.log ' '

logStartTest = (profile) ->
    util.log ' '
    util.log '====> ++++++ STARTING TESTS FOR USER EMAIL ' + profile.email

logEndTest = (errors) ->
    if errors > 0
        util.log '====> [x][x][x] TEST FINISHED WITH ' + errors + ' ERRORS'
    else
        util.log '====> [o][o][o] ALL TESTS PASSED'
    util.log ' '
    util.log ' '

checkResources = (profA, profB) ->
    logTitle 'castle.resourcesList'
    errors = 0
    resA = profA.castle.resourcesList
    resB = profB.castle.resourcesList

    if resA.length == resB.length
        logGood 'resources length match', resA.length
    else
        errors++
        logBad 'resources length doesnt match', resA.length, resB.length

    for rA in resA
        for rB in resB
            if rA.resourceType == rB.resourceType
                if rA.quantity == rB.quantity
                    logGood rA.resourceType + ' quantity equal', rA.quantity
                else
                    errors++
                    logBad rA.resourceType + ' quantity not equal', rA.quantity, rB.quantity

    logSummary 'castle.resourcesList', errors

    return errors

checkCurrency = (profA, profB) ->
    logTitle 'currency.hard'
    errors = 0
    curA = profA.currency.hard
    curB = profB.currency.hard

    if curA != curB
        errors++
        logBad 'Hard quantity not equal', curA, curB
    else
        logGood 'Hard quantity equal', curA

    logSummary 'currency.hard', errors

    return errors

checkBoostRoomProduction = (profA, profB) ->
    logTitle 'castle.roomsList.boostFinishTime'
    errors = 0
    roomListA = profA.castle.roomsList
    roomListB = profB.castle.roomsList

    for roomA in roomListA
        for roomB in roomListB
            if roomA.name == roomB.name and roomA.roomType in ['TAX_COLLECTOR', 'ALCHEMICAL_WORKSHOP']
                if roomA.boostFinishTime != roomB.boostFinishTime
                    errors++
                    logBad 'Boost finish time for ' + roomA.name + ' not equal', roomA.boostFinishTime, roomB.boostFinishTime
                else
                    logGood 'Boost finish time for ' + roomA.name + ' equal', roomA.boostFinishTime

    logSummary 'castle.roomsList.boostFinishTime', errors

    return errors

checkBuildingStartTs = (profA, profB) ->
    logTitle 'castle.roomsList.buildingStartTimestamp'
    errors = 0
    roomListA = profA.castle.roomsList
    roomListB = profB.castle.roomsList

    for roomA in roomListA
        for roomB in roomListB
            if roomA.name == roomB.name
                if roomA.buildingStartTimestamp != roomB.buildingStartTimestamp
                    errors++
                    logBad 'Build start time for ' + roomA.name + ' not equal', roomA.buildingStartTimestamp, roomB.buildingStartTimestamp
                else
                    logGood 'Build start time for ' + roomA.name + ' equal', roomA.buildingStartTimestamp

    logSummary 'castle.roomsList.buildingStartTimestamp', errors

    return errors

checkRoomLevel = (profA, profB) ->
    logTitle 'castle.roomsList.roomLevel'
    errors = 0
    roomListA = profA.castle.roomsList
    roomListB = profB.castle.roomsList

    for roomA in roomListA
        for roomB in roomListB
            if roomA.name == roomB.name
                if roomA.roomLevel != roomB.roomLevel
                    errors++
                    logBad 'Room level for ' + roomA.name + ' not equal', roomA.roomLevel, roomB.roomLevel
                else
                    logGood 'Room level for ' + roomA.name + ' equal', roomA.roomLevel

    logSummary 'castle.roomsList.roomLevel', errors

    return errors

checkProdQuantity = (profA, profB) ->
    logTitle 'castle.roomsList.resourceProdQuantity'
    errors = 0
    roomListA = profA.castle.roomsList
    roomListB = profB.castle.roomsList

    for roomA in roomListA
        for roomB in roomListB
            if roomA.name == roomB.name and roomA.roomType in ['TAX_COLLECTOR', 'ALCHEMICAL_WORKSHOP']
                if roomA.resourceProdQuantity != roomB.resourceProdQuantity
                    errors++
                    logBad 'Room resourceProdQuantity for ' + roomA.name + ' not equal', roomA.resourceProdQuantity, roomB.resourceProdQuantity
                else
                    logGood 'Room resourceProdQuantity for ' + roomA.name + ' equal', roomA.resourceProdQuantity

    logSummary 'castle.roomsList.resourceProdQuantity', errors

    return errors

checkLastCollectTime = (profA, profB) ->
    logTitle 'castle.roomsList.lastCollectTime'
    errors = 0
    roomListA = profA.castle.roomsList
    roomListB = profB.castle.roomsList

    for roomA in roomListA
        for roomB in roomListB
            if roomA.name == roomB.name and roomA.roomType in ['TAX_COLLECTOR', 'ALCHEMICAL_WORKSHOP']
                if roomA.lastCollectTime != roomB.lastCollectTime
                    errors++
                    logBad 'Room lastCollectTime for ' + roomA.name + ' not equal', roomA.lastCollectTime, roomB.lastCollectTime
                else
                    logGood 'Room lastCollectTime for ' + roomA.name + ' equal', roomA.lastCollectTime

    logSummary 'castle.roomsList.lastCollectTime', errors

    return errors

checkAmmoProductionList = (profA, profB) ->
    logTitle 'castle.ammoProductionList'
    errors = 0
    ammoA = profA.castle.ammoProductionList
    ammoB = profB.castle.ammoProductionList

    for aA in ammoA
        for aB in ammoB
            if aA.projectileId == aB.projectileId
                if aA.projectileAmount != aB.projectileAmount
                    errors++
                    logBad 'Projectile amount for ' + aA.projectileId  + ' not equal', aA.projectileAmount, aB.projectileAmount
                else
                    logGood 'Projectile amount for ' + aA.projectileId + ' equal', aA.projectileAmount

    logSummary 'castle.ammoProductionList', errors

    return errors

checkRoomPosition = (profA, profB) ->
    logTitle 'castle.layout.0.rooms.position'
    errors = 0
    roomsListA = profA.castle.layout[0].rooms
    roomsListB = profB.castle.layout[0].rooms

    for roomA in roomsListA
        for roomB in roomsListB
            if roomA.roomID == roomB.roomID
                if roomA.position.x == roomB.position.x and roomA.position.y == roomB.position.y
                    logGood 'Room position for ' + roomA.roomID + ' is ok', JSON.stringify(roomB.position)
                else
                    errors++
                    logBad 'Room position for ' + roomA.roomID + ' not equal', JSON.stringify(roomA.position), JSON.stringify(roomB.position)

    logSummary 'castle.layout.0.rooms.position', errors

    return errors

checkAmmoResearch = (profA, profB) ->
    logTitle 'castle.ammoResearch'
    errors = 0
    ammoResearchA = profA.castle.ammoResearch
    ammoResearchB = profB.castle.ammoResearch

    if ammoResearchA.projectileId == ammoResearchB.projectileId
        logGood 'Projectile id same', ammoResearchA.projectileId
    else
        errors++
        logBad 'Different projectile id', ammoResearchA.projectileId, ammoResearchB.projectileId

    if ammoResearchA.projectileLevel == ammoResearchB.projectileLevel
        logGood 'Projectile level same', ammoResearchA.projectileLevel
    else
        errors++
        logBad 'Different projectile level', ammoResearchA.projectileLevel, ammoResearchB.projectileLevel

    if ammoResearchA.researchStartTimestamp == ammoResearchB.researchStartTimestamp
        logGood 'researchStartTimestamp same', ammoResearchA.researchStartTimestamp
    else
        errors++
        logBad 'Different researchStartTimestamp', ammoResearchA.researchStartTimestamp, ammoResearchB.researchStartTimestamp

    logSummary 'castle.ammoResearch', errors

    return errors

exports.testProfile = (profileA, profileB) ->
    logStartTest profileA

    totalErrors = 0
    profA = JSON.parse JSON.stringify profileA
    profB = JSON.parse JSON.stringify profileB

    totalErrors += checkResources profA, profB
    totalErrors += checkCurrency profA, profB
    totalErrors += checkBoostRoomProduction profA, profB
    totalErrors += checkRoomLevel profA, profB
    totalErrors += checkProdQuantity profA, profB
    totalErrors += checkLastCollectTime profA, profB
    totalErrors += checkAmmoProductionList profA, profB
    totalErrors += checkBuildingStartTs profA, profB
    totalErrors += checkRoomPosition profA, profB
    totalErrors += checkAmmoResearch profA, profB

    logEndTest totalErrors

