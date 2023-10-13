
AMI_ID_BY_REGION = {
    'us-east-1': 'ami-9b85eef2',
    'us-west-1': 'ami-9b2d03de',
    'us-west-2': 'ami-77be2f47',
    'eu-west-1': 'ami-f5736381'
}


AWS_KEY_FILE = 'castle-us-west-1-default'

AWS_API_KEY    = ''
AWS_SECRET_KEY = ''

AWS_REGIONS = ('us-west-1',)
AMI_SECURITY_GROUP = 'default'

AMI_TYPES = ('mongodb','castle-api')
AWS_USER_NAME = 'ubuntu'

LOCAL_AWS_KEY_FILE = './deploy_keys/' + AWS_KEY_FILE + '.pem'



