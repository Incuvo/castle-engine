var jStat = require('jStat').jStat;

randomBetaPick = function(enemies_ids, desiredCount) {
    alpha = 5;
    beta = 1;
    var chosen = [];
    if ( desiredCount >= enemies_ids.length ) {
        return enemies_ids
    } 
    for (var i = 0; i < desiredCount; i++) {
        index = Math.floor(jStat.beta.cdf(Math.random(), alpha, beta) * enemies_ids.length)
        //console.log('Taking index nr ' + index);
        chosen.push( enemies_ids.splice(index, 1)[0]); 
    }
    return chosen;
}

module.exports.randomBetaPick = randomBetaPick;