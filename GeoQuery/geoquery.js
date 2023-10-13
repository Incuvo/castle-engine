var http = require('http');

function GeoQuery() {
}

GeoQuery.prototype.geoquery = function(options,next) {
    
    var timeout = options.timeout || 1000;
    var serviceHost = options.serviceHost || '172.31.7.71';
    var servicePort = options.servicePort || 80;
    var servicePath = options.servicePath || '/location';
    var queryIP = '/' + options.ip;
    
    var hasTimeout = false;
    var opts = {
        hostname: serviceHost,
        path: servicePath + queryIP,
        method: 'GET',
        port: servicePort,
    };
    
    var req = http.request(opts, function(res) {
        res.setEncoding('utf8');
        var output = '';
        res.on('data', function (chunk) { 
            output += chunk; }
        );
        res.on('end', function() { 
            if(!hasTimeout) {
                var data = JSON.parse(output);
                return next(null, {
                    ip: options.ip,
                    continent_code: data.continent_code,
                    country_code: data.country_code3,
                    country: data.country,
                    latitude: data.latitude,
                    longitude: data.longitude,
                    timezone : data.timezone,
                    diff: data.offset || (Math.round(data.longitude * 24 / 360) * 3600),
                });
            }; 
        });
    });
    
    req.on('error', function(e) {if(!hasTimeout) return next(e); });
    req.setTimeout(timeout, function() { 
        hasTimeout=true; 
        return next(new Error('timeout')); 
    });
    req.end();

};

module.exports = new GeoQuery();
