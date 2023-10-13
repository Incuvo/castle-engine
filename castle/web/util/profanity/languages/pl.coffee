rawNouns = [
                    'dupa',
                    #'cip',
                    'cipeczka',
                    'chuj',
                    'kurw',
                    'kutas',
                    #'porn',
                    'penis',
                    'sex',
                    #'wtf'
        ]



rawVerbs = ["jebać","kurwić"]


noun = ["dupa","spierdolina"]


adjective = [ "chędożony","pierdolony"]



appendNonWordExpression = (prefix, texts)->

    out = []

    for word in texts
        regExWord = ""
        for char in word
            regExWord+=char + "[\\W|\\d|"+char+"]*"

        out.push prefix + regExWord
    return out

verbs = appendNonWordExpression "(za|prze|a|u|e|[ćc]|n[ya]|wy)?", rawVerbs
nouns = appendNonWordExpression "(za|prze|a|u|e|[ćc]|n[ya]|wy)?", rawNouns

words = nouns.join('(a|u|e|i?[ćc]|n[ya]|w[yo]|y|i[eę])?|') + '(a|u|e|i?[ćc]|n[ya]|w[yo]|y|i[eę])?|' + verbs.join('(u|e|[i?ćc]|n[ya]|w[yo]|y|ka|ić|i[eę])?|') + "(u|e|[i?ćc]|n[ya]|w[yo]|y|ka|ić|i[eę])?"

wordsRegExpStr = '\\b('+words+')\\b'
wordsRegExpStr2 = '('+words+')'

exports.hasSwearWords = (texts) ->

    matchObj = exports.matchSwearWords(texts)

    return matchObj != null


exports.hasSwearWords2 = (texts) ->


    matchObj = exports.matchSwearWords2(texts)

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

exports.disabled = true
