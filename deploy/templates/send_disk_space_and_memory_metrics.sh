#!/bin/bash

path='/'

INSTANCE_ID=`type -P ec2metadata &>/dev/null && ec2metadata --instance-id || echo "local"`

memtotal=`free -m | grep 'Mem' | tr -s ' ' | cut -d ' ' -f 2`
memfree=`free -m | grep 'buffers/cache' | tr -s ' ' | cut -d ' ' -f 4`
let "usedMemoryPercent=100-memfree*100/memtotal"

#freespace=`df --local --block-size=1M $path | grep $path | tr -s ' ' | cut -d ' ' -f 4`
usedDiskSpacePercent=`df --local $path | grep $path | tr -s ' ' | cut -d ' ' -f 5 | grep -o "[0-9]*"`

aws_region=`type -P ec2metadata &>/dev/null && ec2metadata --availability-zone | grep -Po "(us|sa|eu|ap)-(north|south)?(east|west)?-[0-9]+" || echo "local"`


namespace=${1:-'System/Linux'}

python <<END
import httplib2, sys, os, base64, hashlib, hmac, time
import json as simplejson
from urllib import urlencode, quote_plus
 
aws_key = 'AKIAIPD6IDDWJJYEQ7XA'
aws_secret_key = '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'
 
namespace            = 'System/Linux'

usedDiskSpacePercent = '$usedDiskSpacePercent'
usedMemoryPercent    = '$usedMemoryPercent' 
instanceid           = '$INSTANCE_ID'
namespace            = '$namespace'
 
params = {'Namespace': namespace,
 'MetricData.member.1.MetricName': 'UsedDiskSpacePercent',
 'MetricData.member.1.Value': usedDiskSpacePercent,
 'MetricData.member.1.Unit': 'Percent',
 'MetricData.member.1.Dimensions.member.1.Name': 'InstanceId',
 'MetricData.member.1.Dimensions.member.1.Value': instanceid,
 'MetricData.member.2.MetricName': 'UsedMemoryPercent',
 'MetricData.member.2.Value': usedMemoryPercent,
 'MetricData.member.2.Unit': 'Percent',
 'MetricData.member.2.Dimensions.member.1.Name': 'InstanceId',
 'MetricData.member.2.Dimensions.member.1.Value': instanceid
}
 
def getSignedURL(key, secret_key, action, parms):
 
    # base url
    base_url = "monitoring.$aws_region.amazonaws.com"
 
    # build the parameter dictionary
    url_params = parms
    url_params['AWSAccessKeyId'] = key
    url_params['Action'] = action
    url_params['SignatureMethod'] = 'HmacSHA256'
    url_params['SignatureVersion'] = '2'
    url_params['Version'] = '2010-08-01'
    url_params['Timestamp'] = time.strftime("%Y-%m-%dT%H:%M:%S.000Z", time.gmtime())
 
    # sort and encode the parameters
    keys = url_params.keys()
    keys.sort()
    values = map(url_params.get, keys)
    url_string = urlencode(zip(keys,values))
 
    # sign, encode and quote the entire request string
    string_to_sign = "GET\n%s\n/\n%s" % (base_url, url_string)
    signature = hmac.new( key=secret_key, msg=string_to_sign, digestmod=hashlib.sha256).digest()
    signature = base64.encodestring(signature).strip()
    urlencoded_signature = quote_plus(signature)
    url_string += "&Signature=%s" % urlencoded_signature
 
    # do it
    foo = "http://%s/?%s" % (base_url, url_string)
    return foo
 
class Cloudwatch:
    def __init__(self, key, secret_key):
        self.key = os.getenv('AWS_ACCESS_KEY_ID', key)
        self.secret_key = os.getenv('AWS_SECRET_ACCESS_KEY_ID', secret_key)
 
    def putData(self, params):
        signedURL = getSignedURL(self.key, self.secret_key, 'PutMetricData', params)
        h = httplib2.Http()
        resp, content = h.request(signedURL)
 
cw = Cloudwatch(aws_key, aws_secret_key)
cw.putData(params)

END
