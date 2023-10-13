fs = require 'fs'


# Parses Webassets JSON manifest file and builds URL paths with version tags.
#
# Define `builder` and `formatter` to customize the URLs.
module.exports = (filename, options) ->
    #docs
    options = options || {}
    assets = {}

    if not options.builder?
        options.builder = (path, version) ->
            return path + '?v=' + version

    manifest = JSON.parse fs.readFileSync filename, 'utf-8'

    for asset, version of manifest
        if options.formatter?
            url = options.formatter asset
        else
            if options.removePrefix?
                url = asset.replace new RegExp('^' + options.removePrefix), ''
            else
                url = asset

        if options.addPrefix?
            url = options.addPrefix + url

        assets[asset] = options.builder url, version

    return assets
