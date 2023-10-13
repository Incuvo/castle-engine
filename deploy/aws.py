import sys

import os
from time import sleep
import time
from fabric.api import *
from fabric.contrib.files import upload_template, put
from fabric.colors import green as _green, yellow as _yellow
from fabtools.supervisor import restart_process

from boto.ec2.elb import ELBConnection
from boto.ec2.elb import HealthCheck

from boto.ec2 import EC2Connection, get_region, connect_to_region
from boto.ec2.blockdevicemapping import BlockDeviceMapping, BlockDeviceType
from boto.s3.connection import S3Connection
from boto.s3.key import Key
import boto

import aws_config as config

#rafal.koffer
#KS{o2oqU%Ui2


def _poll_for_ssh_connectivity(instance, username, key_filename):
        """ 
        Using the ssh library, try to connect until we get a legit connection.
        """
        hostname = instance.public_dns_name
 
        wait_time = 10
        max_wait_time = 600 
        total_time = 0 
 
        print "Waiting for ssh connectivity [%s] ..." % hostname
 
        with settings(hide('warnings', 'running', 'stdout', 'stderr'), user=username, host_string=hostname, key_filename=key_filename):
            while True:
 
                print ".",
                sys.stdout.flush()
 
                try:
                    run('ls /')
 
                    # if we got here, the command must have worked...
                    break
 
                except Exception as ex: 
                    time.sleep(wait_time)
                    total_time += wait_time
                    if total_time >= max_wait_time:
                        print ("Timed out waiting for an instance to get ssh ready - instance [%s]" % instance.id)
                        break
 
        print "Connection ok for [%s]" % hostname





@task
def restart_castle_api_instance(aws_regions, environment='production'):

    if ',' in aws_regions:
        aws_region_list = aws_regions.split(',')
    else:
        aws_region_list = [aws_regions]

    for aws_region in aws_region_list:

        if aws_region not in config.AWS_REGIONS:
            print('Unknown region {0}'.format(aws_region))
            continue

        ec2_connection = _get_ec2_connection(aws_region)


        reservation = ec2_connection.get_all_instances(filters={'tag:type':"castle-api", 'tag:environment':environment, 'instance-state-name':'running'})

        instance_count = len(reservation)

        print '>> Found ' + str(instance_count) + ' castle api instances\n'

        idx = 1
        for r in reservation:
            for instance in r.instances:
                with settings(host_string=instance.public_dns_name, key_filename=config.LOCAL_AWS_KEY_FILE,user=config.AWS_USER_NAME, connection_attempts=10):
                    try:
                        print '>> Start restaring (' + str(idx) +'/' + str(instance_count) + ') of instance ' + instance.id
                        restart_process('castle-api')
                        print '<< End restaring (' + str(idx) +'/' + str(instance_count) + ') of instance ' + instance.id + '\n'
                    except Exception as ex:
                        print ex

                idx = idx + 1

        print '>> Done ... '


@task
def update_castle_api_instance(aws_regions, environment='production'):

    if ',' in aws_regions:
        aws_region_list = aws_regions.split(',')
    else:
        aws_region_list = [aws_regions]

    for aws_region in aws_region_list:

        if aws_region not in config.AWS_REGIONS:
            print('Unknown region {0}'.format(aws_region))
            continue

        ec2_connection = _get_ec2_connection(aws_region)


        reservation = ec2_connection.get_all_instances(filters={'tag:type':"castle-api", 'tag:environment':environment, 'instance-state-name':'running'})

        instance_count = len(reservation)

        print '>> Found ' + str(instance_count) + ' castle api instances\n'

        idx = 1
        for r in reservation:
            for instance in r.instances:
                with settings(host_string=instance.public_dns_name, key_filename=config.LOCAL_AWS_KEY_FILE,user=config.AWS_USER_NAME, connection_attempts=10):
                    try:
                        print '>> Start updating (' + str(idx) +'/' + str(instance_count) + ') of instance ' + instance.id
                        execute('update_and_restart_castle_api')
                        print '<< End updating (' + str(idx) +'/' + str(instance_count) + ') of instance ' + instance.id + '\n'
                    except ex:
                        print ex

                idx = idx + 1

        print '>> Done ... '


@task
def show_logs_castle_api_instance(aws_regions, environment='production'):

    if ',' in aws_regions:
        aws_region_list = aws_regions.split(',')
    else:
        aws_region_list = [aws_regions]

    for aws_region in aws_region_list:

        if aws_region not in config.AWS_REGIONS:
            print('Unknown region {0}'.format(aws_region))
            continue

        ec2_connection = _get_ec2_connection(aws_region)


        reservation = ec2_connection.get_all_instances(filters={'tag:type':"castle-api", 'tag:environment':environment, 'instance-state-name':'running'})

        instance_count = len(reservation)

        print '>> Found ' + str(instance_count) + ' castle api instances\n'

        idx = 1
        for r in reservation:
            for instance in r.instances:
                with settings(host_string=instance.public_dns_name, key_filename=config.LOCAL_AWS_KEY_FILE,user=config.AWS_USER_NAME, connection_attempts=10):
                    try:
                        print '>> Start (' + str(idx) +'/' + str(instance_count) + ') of instance ' + instance.id
                        execute('show_logs_castle_api')
                        print '<< End (' + str(idx) +'/' + str(instance_count) + ') of instance ' + instance.id + '\n'
                    except ex:
                        print ex

                idx = idx + 1

        print '>> Done ... '

@task
def launch_castle_api_instance(aws_regions,instance_type='m1.small', environment='production', security_group='default', add_to_elb = True):

    if ',' in aws_regions:
        aws_region_list = aws_regions.split(',')
    else:
        aws_region_list = [aws_regions]

    for aws_region in aws_region_list:

        if aws_region not in config.AWS_REGIONS:
            print('Unknown region {0}'.format(aws_region))
            continue

        ec2_connection = _get_ec2_connection(aws_region)

        zones = ec2_connection.get_all_zones()
 
        zoneStrings = []

        for zone in zones:
            zoneStrings.append(zone.name)

        image = ec2_connection.get_all_images(owners='self',filters={'tag:type':"castle-api"})[0]

        reservation = image.run(key_name=config.AWS_KEY_FILE,security_group_ids=[security_group],instance_type=instance_type)

        instance = reservation.instances[0]

        ec2_connection.create_tags([instance.id], {'type':'castle-api','environment' : environment,'Name':'castle-api'})

        print('spinning up the instance')

        sleep(10)

        instance.update()

        while instance.state != 'running':
            print(_yellow("Instance state: %s" % instance.state))
            sleep(10)
            instance.update()

        if add_to_elb:
            elb_connection = boto.ec2.elb.connect_to_region(aws_region, aws_access_key_id=config.AWS_API_KEY, aws_secret_access_key=config.AWS_SECRET_KEY)
            elb_connection.register_instances('castle-elb',[instance.id])

        print(_green("Instance state: %s" % instance.state))
        print(_green("Public dns: %s" % instance.public_dns_name))
 

@task
def create_ami(aws_regions, ami_type, ami_name, ami_description, root_device='/dev/sda1', root_device_size=8, install_task_name = None, security_group=config.AMI_SECURITY_GROUP,instance_type='t1.micro'):
    """ Creates an EBS backed AMI in one or more AWS regions.

    parameters:
    aws_regions -- Comma delimited list of AWS regions, or single item listing, where the AMI is saved.
    ami_type -- The type of AMI to create. The ami_type determines how the AMI is configured.
    ami_name -- The name to save the AMI under. AMI names are unique within a region.
    ami_description -- The AMI's description.
    root_device -- The device mapping for the AMI's root volume. The AWS device mapping may differ from the device mapping
    used in the virtualized OS. Defaults to /dev/sda1.
    root_device_size -- The size of the root EBS volume in GB.
    """

    if ',' in aws_regions:
        aws_region_list = aws_regions.split(',')
    else:
        aws_region_list = [aws_regions]

    for aws_region in aws_region_list:

        if aws_region not in config.AWS_REGIONS:
            print('Unknown region {0}'.format(aws_region))
            continue

        if ami_type not in config.AMI_TYPES:
            raise ValueError('Unknown AMI Type {0}'.format(ami_type))

        ec2_connection = _get_ec2_connection(aws_region)

        print('Connected to {0}'.format(ec2_connection))

        ami_id = config.AMI_ID_BY_REGION[ec2_connection.region.name]

        root_ebs_device_mapping = _get_block_device_mapping(root_device, root_device_size)

        reservation = ec2_connection.run_instances(ami_id, key_name=config.AWS_KEY_FILE,security_group_ids=[security_group], block_device_map=root_ebs_device_mapping, instance_type=instance_type)

        template_instance = reservation.instances[0]

        print('spinning up the instance')
        sleep(10)

        template_instance.update()

        while template_instance.state != 'running':
            sleep(10)
            template_instance.update()


        _poll_for_ssh_connectivity(template_instance, config.AWS_USER_NAME,config.LOCAL_AWS_KEY_FILE)

        print('configuring instance {0}'.format(template_instance.id))

        with settings(host_string=template_instance.public_dns_name, key_filename=config.LOCAL_AWS_KEY_FILE,
            user=config.AWS_USER_NAME, connection_attempts=10):

            if install_task_name:
                execute(install_task_name)

        # create the AMI based off of our instance
        print('Creating AMI {0}'.format(ami_name))
        new_ami_id = ec2_connection.create_image(template_instance.id, ami_name, ami_description)

        print('Creating new AMI for {0}. AMIID: {1}'.format(ami_name, new_ami_id))
        new_ami = ec2_connection.get_all_images([new_ami_id])[0]
        sleep(20)

        while (new_ami.state == 'pending'):
            new_ami.update()
            sleep(20)

        print('AMI Created')

        ec2_connection.create_tags([new_ami.id], {'Name': ami_name})


        # clean up
        print('Terminating instance')

        while template_instance.state != 'running':
            template_instance.update()
            sleep(20)

        ec2_connection.terminate_instances([template_instance.id])


def _get_ec2_connection(aws_region):
    """ Creates an EC2 Connection for the specified region.

    parameters:
    aws_region -- the aws region code (us-east-1, us-west-1, etc)
    """
    return connect_to_region(aws_region, aws_access_key_id=config.AWS_API_KEY, aws_secret_access_key=config.AWS_SECRET_KEY)

def _get_block_device_mapping(device_name, size):
    """ Returns a block device mapping object for the specified device and size.

    Block Device Mapping is used to associate a device on the VM with an EBS Volume.

    parameters:
    device_name -- The name of the device in the VM, such as /dev/sda1, /dev/sdb1. etc
    size -- The amount of space to allocate for the EBS drive.

    """
    block_device = BlockDeviceType()
    block_device.size = size
    bdm = BlockDeviceMapping()
    bdm[device_name] = block_device

    return bdm