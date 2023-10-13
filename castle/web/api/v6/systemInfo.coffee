fs = require('fs')

exports.pids = {}

exports.getProcessCPUStatPercent = (cb) ->

    currentPid = '' + process.pid

    if not exports.pids[currentPid]?

        last_stat = 
            stats_all : null
            ptime : 0
            utime : 0
            stime : 0

        exports.pids[ currentPid ] = last_stat


    else 
        last_stat = exports.pids[currentPid] 

    fs.readFile '/proc/' + process.pid  + '/stat', 'ascii' , (err, data) ->

        if err 
            return cb err,null
			
        stats_pid = data.split(' ')
        utime = parseInt( stats_pid[13] )
        stime = parseInt( stats_pid[14] )
			
        fs.readFile '/proc/stat', 'ascii', (err,data) ->


            if err
                return cb err,null
				
            stats_all = data.match('cpu +(.*)\n')[1].split(' ')

            sum = 0

            for key of stats_all
                sum = sum + stats_all[key] * 1

            stats_all = sum

            if last_stat.stats_all?

                ptime = utime + stime
                ticks_delta  = (stats_all - last_stat.stats_all)

                percent_proc = (ptime - last_stat.ptime)/ticks_delta * 100
                percent_user = (utime - last_stat.utime)/ticks_delta * 100
                percent_syst = (stime - last_stat.stime)/ticks_delta * 100

                cb( null,  { percent_usage : { proc : percent_proc, user : percent_user, sys : percent_syst, all: percent_proc + percent_user + percent_syst} } )
		
            last_stat.stats_all = stats_all
            last_stat.ptime = ptime
            last_stat.utime = utime
            last_stat.stime = stime

exports.getGlobalMemoryStat = (cb) ->

    fs.readFile '/proc/meminfo', 'ascii', (err, data) ->

        if err 
            return cb err,null
			
        data = data.split('\n')
        meminfos = {}

        data.forEach (item) ->
            item = item.replace(/\s+/, ' ')
            item = item.replace(/\skB/, '')
            item = item.replace(/\:/, '')

            if item != ''
                stats_all = item.match(/([\(\):\w]*)[ ]*([0-9]+)/i)
                key = stats_all[1]
                value = stats_all[2]

                if key? and value?
                    meminfos[key] = value

        memfree  = parseInt( meminfos['MemFree'] )
        memtotal = parseInt( meminfos['MemTotal'] )
        cached   = parseInt( meminfos['Cached'] )
        buffers  = parseInt( meminfos['Buffers'] )

        memory_usage_percent = 100 - ( memfree + buffers + cached ) * 100 / memtotal

        cb null,{ usage_in_perc : memory_usage_percent ,details : data }

