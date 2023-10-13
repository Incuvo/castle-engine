fs            = require 'fs'
directChecker = require './directDictChecker'
util = require 'util'

languages     = {}

langDir = "#{__dirname}/languages/"

fs.readdirSync(langDir).forEach ( langScript ) ->

    if  langScript.match(/[^\.].*?\.coffee$/)
        langName = langScript.replace(/\.coffee$/, '')

        rule = require(langDir + langName)

        if rule and rule.disabled == false
            languages[langName] = require(langDir + langName)
            util.log "[CASTLE API] Profanity Lang #{langName} loaded ... "


langDirectDictDir = "#{__dirname}/languages/dictionary"

fs.readdirSync(langDirectDictDir).forEach ( langDict ) ->

    if  langDict.match(/[^\.].*?\.txt$/)
        langName = langDict.replace(/\.txt$/, '')
        languages[langName] = directChecker.build(langDirectDictDir + '/' + langDict)
        util.log "[CASTLE API] Profanity Direct Lang #{langName} loaded ... "


defaultLangRule = {
    hasSwearWords : () ->
        return false
    hasSwearWords2 : () ->
        return false
}

exports.hasSwearWords = (texts) ->

    for key, object of languages
        if object.hasSwearWords(texts)
            return true

    return false

exports.hasSwearWords2 = (texts) ->

    for key, object of languages
        if object.hasSwearWords2(texts)
            return true

    return false



