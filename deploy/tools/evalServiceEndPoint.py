import os
import sys

from libcloud.compute.types import Provider
from libcloud.compute.providers import get_driver
from libcloud.compute.types import NodeState

def evalServiceEndPoint(config, service_type= 'standalone', regions = 'local', env = 'production', get_attribute = 'private_ips', default_value = 'localhost'):

    result = []

    found_nodes = []

    for region in regions.split(','):        
        for node in config.DRIVER_MAPPING[env][region].list_nodes():
            if node.state == NodeState.RUNNING:

                tags = { k.lower():v.lower() for k,v in node.extra.get('tags',{}).items()}

                node_env      =  tags.get('environment','')
                node_services =  tags.get('type','').split(',')

                if env == node_env and (service_type in node_services or service_type == '*'):
                    found_nodes.append(node)

        nodes_by_priority = sorted(found_nodes, cmp = lambda n1,n2: int(n1.extra.get('tags',{}).get('priority','100')) - int(n2.extra.get('tags',{}).get('priority','100')))

        if len(nodes_by_priority) == 0:
            return [default_value]
        else:
            for node in nodes_by_priority:
                v = getattr(node,get_attribute)

                if isinstance(v, list):
                    result.append(v[0])
                else:
                    result.append(v)

            return result
