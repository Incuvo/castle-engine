fs            = require 'fs'

#case TextManager.ELockKitLanguages.DUTCH:
#return "nl";
#case TextManager.ELockKitLanguages.ENGLISH:
#return "en";
#case TextManager.ELockKitLanguages.FRENCH:
#return "fr";
#case TextManager.ELockKitLanguages.GERMAN:
#return "de";
#case TextManager.ELockKitLanguages.ITALIAN:
#return "it";
#case TextManager.ELockKitLanguages.POLISH:
#return "pl";
#case TextManager.ELockKitLanguages.PORTUGUESE:
#return "pt";
#case TextManager.ELockKitLanguages.SPANISH:
#return "es";
#case TextManager.ELockKitLanguages.SWEDISH:
#return "sv";


appendNonWordExpression = (texts) ->

    out = []

    for word in texts

        regExWord = ""

        if word and word[0] == "#"
            continue

        word = word.toLowerCase()

        for char in word
            if char == '?' or char == '*' or char == '+' or char == '(' or char == ')' or char == '|'
                regExWord+= char
            else
                regExWord+='(' + char + "[\\W|\\d|"+char+"]*)"

        out.push '(' + regExWord + ')'

    return out


exports.build = (dictPath) =>

    dictLines = fs.readFileSync(dictPath).toString().split("\r\n")

    wordsTmp = appendNonWordExpression dictLines
    words    = wordsTmp.join('|')

    wordsRegExpStr = '\\b('+words+')\\b'
    wordsRegExpStr2 = '('+words+')'

    api = {}

    api.hasSwearWords = (texts) ->

        matchObj = api.matchSwearWords(texts)

        return matchObj != null


    api.hasSwearWords2 = (texts) ->

        matchObj = api.matchSwearWords2(texts)

        return matchObj != null

        matchSwearWords = (texts) ->

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

    api.matchSwearWords2 = (texts) ->

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

    api.matchSwearWords = (texts) ->

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


    return api
