nounsRegExpStr = [
                    'fagg?ot',
                    'fudge[\\W|\\d]*packer',
                    'knob[\\W|\\d]*end'
                ]

rawNouns = [
                    'blowjob',
                    'homo',
                    'ballsack',
                    'bollock',
                    'bollok',
                    'biatch',
                    'bloody',
                    #'balls',
                    #'crap',
                    'anal',
                    #'anus', 
                    'vagina',
                    'spunk',
                    'smegma',
                    'slut',
                    'scrotum',
                    'queer',
                    #'pube',
                    'prick',
                    #'poop',
                    'penis',
                    'piss',
                    'idiot',
                    #'twat',
                    #'turd',
                    'tosser',
                    'bastard',
                    #'ass',
                    'ass?hole',
                    #'arse',
                    'arsehole',
                    #'suck',
                    'cock',
                    'shit',
                    #'fag',
                    #'damm', 
                    #'pussy', 
                    #'dick',
                    'dickhead',
                    'cunt', 
                    'bitch', 
                    #'tit',
                    #'pansy', 
                    'shithouse',
                    'bitch',
                    #'jerk',
                    'whore',
                    'whorehouse',
                    #'wank'
                    #'slag',
                    #'omg',
                    'flange',
                    #'feck',
                    'labia',
                    'clitoris',
                    'dildo',
                    #'dyke',
                    'fellate',
                    'fellatio',
                    'jizz',
                    #'lmao',
                    #'lmfao',
                    #'muff',
                    'nigga',
                    'douche',
                    #'porn',
                    'penis',
                    'sex',
                    #'wtf'
                    'suicide'
        ]

rawVerbs =  ['fuck','motherfucker','assfuck','assfucker','felching']

appendNonWordExpression = (texts)->

    out = []

    for word in texts
        regExWord = ""
        for char in word
            regExWord+=char + "[\\W|\\d|"+char+"]*"

        out.push regExWord
    return out

verbs = appendNonWordExpression rawVerbs
nouns = appendNonWordExpression rawNouns

words = nounsRegExpStr.join('s?|') + 's? | ' + nouns.join('s?|') + 's? |' + verbs.join('(a|e|ed|er|ing?)?s?|') + '(a|e|ed|er|ing?)?s?'

wordsRegExpStr = '\\b('+words+')\\b'
wordsRegExpStr2 = '('+words+')'


exports.hasSwearWords = (texts) ->

    matchObj = exports.matchSwearWords(texts)

    if matchObj

        #case isn't it

        if matchObj.index > 0 and matchObj[0][0] == 't' and ( matchObj.input[ matchObj.index - 1] == "'" || matchObj.input[ matchObj.index - 1] == "n")
            return exports.hasSwearWords matchObj.input[ matchObj.index + matchObj[0].length - 1.. ]

    return matchObj != null


exports.hasSwearWords2 = (texts) ->

    matchObj = exports.matchSwearWords2(texts)

    if matchObj

        #case isn't it
        if matchObj.index > 0 and matchObj[0][0] == 't' and ( matchObj.input[ matchObj.index - 1] == "'" || matchObj.input[ matchObj.index - 1] == "n")
            return exports.hasSwearWords2 matchObj.input[ matchObj.index + matchObj[0].length - 1.. ]

    return matchObj != null

exports.matchSwearWords = (texts) ->

    if not texts?
        return null

    if texts instanceof Array
        for text in texts
            matchObj = text.toLowerCase().match(wordsRegExpStr)

            if matchObj != null
                return matchObj
    
        return null
    else
        return texts.toLowerCase().match(wordsRegExpStr)

exports.matchSwearWords2 = (texts) ->

    if not texts?
        return null

    if texts instanceof Array
        for text in texts
            matchObj = text.toLowerCase().match(wordsRegExpStr2)

            if matchObj != null
                return matchObj
    
        return null
    else
        return texts.toLowerCase().match(wordsRegExpStr2)

exports.disabled = false
