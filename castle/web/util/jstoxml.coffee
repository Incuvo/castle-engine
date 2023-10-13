util = require("util")

exports.JsToXml = class JsToXml

    constructor: ->

        @output = ''

    toXml : (obj, objName) ->

        if not obj
            return ""

        if typeof obj == 'string' or obj instanceof String
            @output = "<#{objName}>#{obj}s</#{objName}>"
        else if util.isArray obj
                @output = @listToXml(obj, objName)
            else
                @output = @objToXml(obj)

        return @output

    objToXml  : (obj, objName) ->

        tagStr = ""     
        attributes = {} 
        attrStr = ""    
        childStr = ""   

        for k, v of obj
            if util.isArray v
                childStr += @listToXml( v, k )
            else 
                if typeof v == 'object'
                    childStr += @objToXml( v, k )
                else
                    attributes[k] = v

        if not objName
            return childStr

        # create XML string for attributes
        for k, v of attributes
            attrStr += " #{k}=\"#{v}\""

        # let's assemble our tag string
        if childStr == ""
            tagStr += "<#{objName}#{attrStr} />"
        else
            tagStr += "<#{objName}#{attrStr}>#{childStr}</#{objName}>"

        return tagStr

    listToXml  : (obj, objName) ->
        tagStr = ""
        childStr = ""

        for childObj in obj

            if typeof childObj == 'object'
                # here's some Magic
                # we're assuming that List parent has a plural name of child:
                # eg, persons > person, so cut off last char
                # name-wise, only really works for one level, however
                # in practice, this is probably ok
                childStr += @objToXml( childObj, objName.slice(0, -1) )
            else
                for string in childObj
                    childStr += string

        if not objName
            return childStr
                                
        tagStr += "<#{objName}>#{childStr}</#{objName}>"

        return tagStr
