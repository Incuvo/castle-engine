import os
import sys

from libcloud.compute.types import Provider
from libcloud.compute.providers import get_driver
from libcloud.compute.types import NodeState

def getTag(config, instacne_id, region, tagKey, default_value):

    for node in config.DRIVER_MAPPING['all'][region].list_nodes():
        if node.state == NodeState.RUNNING and node.id == instacne_id:
            tags = { k.lower():v.lower() for k,v in node.extra.get('tags',{}).items()}
            return tags.get(tagKey,default_value)

    return default_value    