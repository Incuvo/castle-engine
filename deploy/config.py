import os
import libcloud
import libcloud.security

from libcloud.compute.types import Provider
from libcloud.compute.providers import get_driver

libcloud.security.CA_CERTS_PATH = [ os.path.dirname(os.path.abspath(__file__)) + '/certs/cacert.pem']

EC2_ACCESS_ID  = 'AKIAJDGBK4JVA2AD4LVQ'
EC2_SECRET_KEY = '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'


DRIVER_MAPPING = { 

    "development" : { 
            "us-west-2" :  get_driver(Provider.EC2_US_WEST_OREGON)(EC2_ACCESS_ID, EC2_SECRET_KEY),
            "us-west-1":  get_driver(Provider.EC2_US_WEST)(EC2_ACCESS_ID, EC2_SECRET_KEY),
            "eu-west-1":  get_driver(Provider.EC2_EU_WEST)(EC2_ACCESS_ID, EC2_SECRET_KEY),
            "local"    :  get_driver(Provider.DUMMY)(0)   
    },
    "production"  : {
        "us-west-2" :  get_driver(Provider.EC2_US_WEST_OREGON)(EC2_ACCESS_ID, EC2_SECRET_KEY),
        "us-west-1":  get_driver(Provider.EC2_US_WEST)(EC2_ACCESS_ID, EC2_SECRET_KEY),
        "eu-west-1":  get_driver(Provider.EC2_EU_WEST)(EC2_ACCESS_ID, EC2_SECRET_KEY),
        "local"    :  get_driver(Provider.DUMMY)(0)   

    },

    "all" : {
        "us-west-2" :  get_driver(Provider.EC2_US_WEST_OREGON)(EC2_ACCESS_ID, EC2_SECRET_KEY),
        "us-west-1" :  get_driver(Provider.EC2_US_WEST)(EC2_ACCESS_ID, EC2_SECRET_KEY),
        "eu-west-1" :  get_driver(Provider.EC2_EU_WEST)(EC2_ACCESS_ID, EC2_SECRET_KEY),
        "local"     :  get_driver(Provider.DUMMY)(0)
    }

}