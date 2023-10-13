import os
import sys
import time
import calendar
import pymongo
import logging


from pymongo import MongoClient
from bson import json_util

from datetime import datetime

sys.path = [ os.path.dirname(os.path.abspath(__file__)) + '/lib' ] + sys.path

import patch

from flask import session, Flask, g, request, render_template, redirect, url_for, Response
from werkzeug import secure_filename
from functools import wraps
from webware.TaskKit.Scheduler import Scheduler
from webware.TaskKit.Task import Task

from boto.ec2 import EC2Connection, get_region, connect_to_region
from boto.ec2.blockdevicemapping import BlockDeviceMapping, BlockDeviceType
from boto.s3.connection import S3Connection

import httplib2
import simplejson as json

from flaskext.auth.auth import Auth
from flaskext.auth.auth import AuthUser
from flaskext.auth.auth import get_current_user_data
from flaskext.auth.auth import login_required
    
 
def roundToNear (value, roundVal):
    return ((value - (divmod(value , roundVal)[1])) / roundVal) * roundVal

def UTCTimeStamp():

    now = datetime.utcnow()
    ts = calendar.timegm(now.utctimetuple()) * 1000
    return (ts + (now.microsecond / 1000), now)


app = Flask(__name__)

app.secret_key = '43Zrw4j;3yXtR~XHwgjmg]1dX/,sTY'
auth = Auth(app)

scheduler = Scheduler()

environment = 'production'

aws_access_key_id = 'AKIAJSDZ644IKVOLKYBA'
aws_secret_access_key = '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'


app.metricHosts = []


class EvalCastleApiAWSEndPointsTask(Task):
  
    def evalAWSEndPoints(self,aws_self_region, aws_regions, environment):

        endPoints = []

        if ',' in aws_regions:
            aws_region_list = aws_regions.split(',')
        else:
            aws_region_list = [aws_regions]


        for aws_region in aws_region_list:
            ec2_connection = connect_to_region(aws_region, aws_access_key_id=aws_access_key_id, aws_secret_access_key=aws_secret_access_key)
            reservation = ec2_connection.get_all_instances(filters={'tag:type':"castle-api", 'tag:environment':environment, 'instance-state-name':'running'})

            for r in reservation:
                for instance in r.instances:
                    if aws_region == aws_self_region: 
                        endPoints.append(instance.private_dns_name)
                    else:
                        endPoints.append(instance.public_dns_name)

        
        return endPoints

    def run(self):

        try:
            if self.proceed():
                app.metricHosts = self.evalAWSEndPoints(app.currnet_region, app.watch_regions,app.environemnt)
        except ex:
            print ex
        


class MetricCollectorTask(Task):
  
    def __init__(self):
        
        self.client  = MongoClient('localhost', 27017)
        self.db      = self.client['castle-stat']

        if not 'metrics' in self.db.collection_names():
            self.metrics = self.db.create_collection('metrics', capped=True, size=1024*1024*1024*15)
        else:
            self.metrics = self.db['metrics']

        self.metrics.create_index([("ts", pymongo.DESCENDING)])

    def getMetrick(self, host):

        st = time.time()
        resp, content = httplib2.Http().request('http://'+ host + ':8000/status')
        et = time.time()

        return [resp, content, int((et - st) * 1000)]

    def run(self):

        try:
            if self.proceed():

                ts = UTCTimeStamp()

                tick_timestamp = ts[0]
                now            = ts[1]


                resolution = {
                    'y' : now.year,
                    'mo' : now.month,
                    'd' : now.day,
                    'h' : now.hour,
                    'm' : now.minute,
                    's10' : roundToNear(now.second,10),
                    's5' : roundToNear(now.second,5),
                    's' : now.second,
                }

                for host in app.metricHosts:

                    metric = {}

                    metric['ts']    = int(tick_timestamp)
                    metric['res']   = resolution
                    metric['host']  = host

                    metricsRes = self.getMetrick(host)

                    if metricsRes:
                        response = metricsRes[0]            
                        content  = metricsRes[1]            
                        rtime    = metricsRes[2]            

                        metric['rtime'] = rtime

                        nodes = json.loads(content)

                        nodeId = 0

                        for node in nodes:
                            http_methods = node.get('http',None)

                            if http_methods:
                                for method in http_methods:
                                    for method_name, stats in method.items():
                                        for path,stat in stats.items():
                                            http_metric = dict(metric,**{'nodeId':nodeId,'type':'http', 'value' : stat,'method' : method_name,'path':path})
                                            self.metrics.insert(http_metric)

                                del node['http']

                            general_metric = dict(metric,**{'nodeId':nodeId,'type':'general', 'value' : node})

                            self.metrics.insert(general_metric)
                            nodeId = nodeId + 1
        except Exception,ex:
            print 'Exception :%s' % ex
            



@app.before_request
def init_users():
    admin = AuthUser(username='szef')
    admin.set_and_encrypt_password('1ca80df6cfefc3c8b6368f4ae40141e7')
    g.users = {'szef': admin}




@app.route('/_internal/server/health/rejbuh9tbwf9x7jm', methods=['HEAD'])
def health():
    return Response('', 200)


@app.route('/login', methods=['GET','POST'])
def login():

    session.permanent = True
    if request.method == 'POST':
        username = request.form['username']
        if username in g.users:
            if g.users[username].authenticate(request.form['password']):
                return Response('{ success: true }', 200)

        return Response('{ success: false, errors: { reason: "Login failed. Try again." }}', 200)

    return render_template('auth.html', timestamp = UTCTimeStamp()[0] )



@login_required(login)
def metrics():
    session.permanent = True

    utcTime = UTCTimeStamp()
    current_timestamp = utcTime[0]

    resolution              = request.args.get('res', 's')
    metric_type             = request.args.get('metric_type', 'http')
    http_method             = request.args.get('http_method', 'all')
    http_path               = request.args.get('http_path', '*')
    projection_path         = request.args.get('projection_path', '$value.meter.currentRate')
    values_aggregator_func  = request.args.get('agrFunc','avg')
    nodes_aggregator_func  = request.args.get('nodesAgrFunc','sum')
    fromTimestamp           = int(request.args.get('fromTimestamp', str(current_timestamp - 1000 * 30)))
    toTimestamp             = int(request.args.get('toTimestamp', str(current_timestamp)))

    projection_value = ""

    value_aggregator = {}
    nodes_aggregator = {}

    nodes_aggregator_id = {
        "_id" : { "res" : "$res" , "ts" : "$ts" },
        "sum_value" : { "$" + nodes_aggregator_func : "$value" }
    }

    if metric_type == 'http':
        nodes_aggregator_id['_id']['method'] = "$method"
        nodes_aggregator_id['_id']['path'] =  "$path"

    res_id = {}

    if resolution == 's':
        res_id["s" ] = "$_id.res.s"
        res_id["m" ] = "$_id.res.m"
        res_id["h" ] = "$_id.res.h"
        res_id["d" ] = "$_id.res.d"
        res_id["mo"] = "$_id.res.mo"
        res_id["y" ] = "$_id.res.y"
    elif resolution == 's5':
        res_id["s5"] = "$_id.res.s5"
        res_id["m" ] = "$_id.res.m"
        res_id["h" ] = "$_id.res.h"
        res_id["d" ] = "$_id.res.d"
        res_id["mo"] = "$_id.res.mo"
        res_id["y" ] = "$_id.res.y"
    elif resolution == 's10':
        res_id["s10"] = "$_id.res.s10"
        res_id["m"  ] = "$_id.res.m"
        res_id["h"  ] = "$_id.res.h"
        res_id["d"  ] = "$_id.res.d"
        res_id["mo" ] = "$_id.res.mo"
        res_id["y"  ] = "$_id.res.y"
    elif resolution == 'm':
        res_id["m" ] = "$_id.res.m"
        res_id["h" ] = "$_id.res.h"
        res_id["d" ] = "$_id.res.d"
        res_id["mo"] = "$_id.res.mo"
        res_id["y" ] = "$_id.res.y"
    elif resolution == 'h':
        res_id["h" ] = "$_id.res.h"
        res_id["d" ] = "$_id.res.d"
        res_id["mo"] = "$_id.res.mo"
        res_id["y" ] = "$_id.res.y"
    elif resolution == 'd':
        res_id["d" ] = "$_id.res.d"
        res_id["mo"] = "$_id.res.mo"
        res_id["y" ] = "$_id.res.y"
    elif resolution == 'mo':
        res_id["mo"] = "$_id.res.mo"
        res_id["y" ] = "$_id.res.y"
    elif resolution == 'y':
        res_id["y" ] = "$_id.res.y"
    
    values_aggregator_id = {
        "_id" : { "res" : res_id },
        "value" : { "$" + values_aggregator_func : "$sum_value" }
    }

    if metric_type == 'http':
        values_aggregator_id['_id']['method'] = "$_id.method"
        values_aggregator_id['_id']['path'] =  "$_id.path"


    aggregate_pipeline = []

    if metric_type == 'http':
        aggregate_pipeline.append({"$match" : {"ts" : { "$gte": fromTimestamp,"$lte": toTimestamp },"type" : metric_type,"path" : http_path,"method" : http_method}})
        aggregate_pipeline.append({"$project": {"ts" : 1 , "res" : 1, "path" : 1, "method" : 1, "value" : projection_path}})
    else:
        aggregate_pipeline.append({"$match" : {"ts" : { "$gte": fromTimestamp,"$lte": toTimestamp },"type" : metric_type}})
        aggregate_pipeline.append({"$project": {"ts" : 1 , "res" : 1,"value" : projection_path}})

    aggregate_pipeline.append({"$group": nodes_aggregator_id})
    aggregate_pipeline.append({"$group": values_aggregator_id})
    aggregate_pipeline.append({"$project": {"_id":"$null","value" : "$value", "res" : "$_id.res"}})
    aggregate_pipeline.append({"$sort": {"res.y": 1, "res.mo": 1, "res.d": 1, "res.h": 1, "res.m": 1, "res.s10": 1, "res.s5": 1,  "res.s": 1}})

    res = app._collectorTask.metrics.aggregate(aggregate_pipeline)


    result_list = res['result']

    result = {
            "data" : res['result'],
            'total' : len(result_list),
            'success' : True,
            'message' : 'ok',
    }


    return json.dumps(result,sort_keys=True, indent=4, default=json_util.default)

@login_required(login)
def metricsInfo():
    session.permanent = True

    utcTime = UTCTimeStamp()
    current_timestamp = utcTime[0]


    res = app._collectorTask.metrics.aggregate([
            
            {"$match" : {"ts" : {
                                "$gte": current_timestamp - 1000*5,
                                "$lte": current_timestamp
                        }
                       }
            },
            {"$group": {"_id" : {"type" : "$type","method" : "$method","path" : "$path" },"count": {"$sum" : 1 }}},
            {"$project": {"_id":"$null", "type" : "$_id.type", "path" : "$_id.path", "method" : "$_id.method"}},

        ])

    json_res = json.dumps(res['result'],sort_keys=True, indent=4, default=json_util.default)

    return json_res


@login_required(login)
def index():
    session.permanent = True
    return render_template('index.html', timestamp = UTCTimeStamp()[0] )



#routes
app.add_url_rule('/','index', index, methods=['GET'])
app.add_url_rule('/metricsInfo', '/metricsInfo', metricsInfo, methods=['GET'])
app.add_url_rule('/metrics', '/metrics', metrics, methods=['GET'])
app.add_url_rule('/login', '/login', login, methods=['GET','POST'])


use_reloader = os.getenv('use_reloader',False)

if use_reloader and not os.environ.get('WERKZEUG_RUN_MAIN'):
    pass
    #print('startup: pid %d is the werkzeug reloader' % os.getpid())
else:
    argLen = len(sys.argv)

    if argLen > 2:
        app.currnet_region = sys.argv[1]
        app.watch_regions = sys.argv[2]
        if argLen > 3:
            app.environemnt = sys.argv[3]
        else:
            app.environemnt = 'production'

        scheduler.addPeriodicAction(time.time(), 30 ,EvalCastleApiAWSEndPointsTask(), 'EvalCastleApiAWSEndPointsTask')

    elif argLen == 2:

        hosts = sys.argv[1]

        if ',' in hosts:
            hosts = hosts.split(',')
        else:
            hosts = [hosts]

        for host in hosts:
            app.metricHosts.append(host)

    elif argLen == 1:
        app.metricHosts.append('127.0.0.1')

    collectorTask = MetricCollectorTask()
    app._collectorTask = collectorTask
    scheduler.addPeriodicAction(time.time(), 2 ,collectorTask, 'MetricCollectorTask')
    scheduler.start()


    log = logging.getLogger('werkzeug')
    log.disabled = True

    #handler = logging.handlers.RotatingFileHandler(os.path.dirname(os.path.abspath(__file__))  + '/log/monitor.log',maxBytes=1024 * 1024 * 100,backupCount = 20)
    #handler.setFormatter( logging.Formatter('%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'))
    #app.logger.addHandler(handler)
    #app.logger.setLevel(logging.INFO)


    #print('startup: pid %d is the active werkzeug' % os.getpid())


if __name__ == '__main__':
    app.run(debug=True, port=8888, host="0.0.0.0", use_reloader=use_reloader)
    scheduler.stop()
