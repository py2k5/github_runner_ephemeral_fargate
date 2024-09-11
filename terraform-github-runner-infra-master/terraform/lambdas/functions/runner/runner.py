import os
import requests
import time
import jwt
import boto3
from aws_lambda_powertools import Logger

logger = Logger()

ssm = boto3.client('ssm', region_name='ap-southeast-2')
ecs_client = boto3.client('ecs')

def create_registration_token(org_name, token):

    url = f"https://api.github.com/orgs/{org_name}/actions/runners/registration-token"

    headers = {"Authorization": f"token {token}", 'Accept': 'application/vnd.github.v3+json'}
    response = requests.post(url, headers=headers)

    if response.status_code == 201:
        return response.json()['token']
        
    else:
        raise Exception(f"Failed to create registration token: {response.text}")

    
def get_installation_id(body, org_name):
    for installation in body:
        if installation['account']['login'] == org_name:
            return installation['id']
    raise Exception(f"Installation ID not found for {org_name}")

def get_github_runner_installation_token(org_name):
    if os.getenv("GITHUB_APPID_PATH") is None or os.getenv("GITHUB_APP_PRIVATE_KEY_PATH") is None:
        logger.error("Environment variables GITHUB_APP_ID_PATH or GITHUB_APP_PRIVATE_KEY_PATH is not set in lambda environment")
        return {
            'statusCode': 500,
            'body': 'GITHUB_APP_ID_PATH or GITHUB_APP_PRIVATE_KEY_PATH is not set in Lambda environment variables'
        }
 
    appid = get_parameter(os.getenv("GITHUB_APPID_PATH"))
    key = get_parameter(os.getenv("GITHUB_APP_PRIVATE_KEY_PATH"))
    secret= key.encode()
    now=int(time.time())
    payload = {
                    'iat': now - 60,
                    'exp': now + 600,
                    'iss': appid
                }


    encoded = jwt.encode(payload, secret, algorithm="RS256")

    # If you are using a version of PyJWT prior to 2.0, jwt.encode returns a byte string, rather than a string.
    # If the token is a byte string, convert it to a string.
    if isinstance(encoded, bytes):
        encoded = encoded.decode('utf-8')

    try:
        header = {'Authorization': "Bearer " + encoded, 'Accept': 'application/vnd.github.v3+json'}
        response = requests.get('https://api.github.com/app/installations', headers=header)

        try:
            body=response.json()
            installation_id = get_installation_id(body, org_name)

            header = {'Authorization': "Bearer " + encoded, 'Accept': 'application/vnd.github.v3+json'}

            
            insttokenbody = requests.post(f'https://api.github.com/app/installations/{str(installation_id)}/access_tokens', headers=header)
            insttoken=insttokenbody.json()
            return {
                        'token': insttoken["token"],
                        'statusCode': 200
            }   
        except Exception as e:
            logger.info(f"Failed API https://api.github.com/app/installations/{str(installation_id)}/access_tokens: {e}")
            return {
                'statusCode': 500,
                'body': f'Failed API https://api.github.com/app/installations/{str(installation_id)}/access_tokens: {e}'
            }
    except Exception as e:
        logger.info(f"Failed API https://api.github.com/app/installations: {e}")
        return {
            'statusCode': 500,
            'body': f'Failed API https://api.github.com/app/installations: {e}'
        }

def get_parameter(parameter_name):
    """Retrieves a parameter from the SSM Parameter Store.

    Args:
        parameter_name (str): The name of the parameter.

    Returns:
        str: The value of the parameter.
    """
    
    ssm_client = boto3.client('ssm', region_name='ap-southeast-2')
    response = ssm_client.get_parameter(Name=parameter_name, WithDecryption=True)
    parameter_value = response['Parameter']['Value']
    return parameter_value


def create_runner(payload):
    try:
        org_name = payload['repository']['owner']['login']
        workflow_name = payload["workflow_job"]["workflow_name"].replace(" ", "").lower()
        labels = payload['workflow_job']['labels']

        resp = get_github_runner_installation_token(org_name)
        token = resp.get('token')
        logger.info(f"Got the token from get_github_runner_installation_token")
        registration_token = create_registration_token(org_name, token)
        

        logger.info(f'Attempting to launch a new runner') 
        try:
            start_runner(registration_token, org_name, labels, workflow_name )
            
            return {
                'statusCode': 200,
                'body': 'Runner spun up'
            }
        except Exception as e:
            logger.error(f'Error spinning up runner: {e}')
            return {
                'statusCode': 500,
                'body': f'Failed to spin up runner: {e}'
            }
    except Exception as e:
        logger.error(f'Error getting registration token: {e}')
        return {
            'statusCode': 500,
            'body': f'Failed to get registration token: {e}'
        }


    
    
def start_runner(reg_token, org_name, labels, workflow_name):
    cluster_name = os.getenv("ECS_CLUSTER")
    task_defn = os.getenv("TASK_DEFINITION")
    subnet_ids = os.getenv("SUBNETS")
    if isinstance(subnet_ids, str):
        subnet_ids = subnet_ids.split(',')
    security_group = os.getenv("SECURITY_GROUPS")
    if isinstance(security_group, str):
        security_group = security_group.split(',')
    container_name = os.getenv("CONTAINER_NAME")

    #TODO - improvement to check if environment variables are set. If not return proper error message
    if any(value is None for value in [cluster_name, task_defn, subnet_ids, security_group, container_name ]):
        raise "Some environment variable is not set or None. Please check lambda environment settings."

    # if labels is list join them to string or else use it as it is
    if isinstance(labels, list):
        labels = ','.join(labels)

    runner_envs = [
        {'name': 'WORKFLOW_NAME', 'value': workflow_name},
        {'name': 'LABELS', 'value': labels},
        {'name': 'REG_TOKEN', 'value': reg_token },
        {'name': 'GITHUB_ORG', 'value': org_name}
    ]
    
    response = ecs_client.run_task(
        cluster = cluster_name,
        taskDefinition = task_defn,
        launchType = 'FARGATE',
        networkConfiguration = {
        'awsvpcConfiguration' : {
            'subnets' : subnet_ids,
            'securityGroups' : security_group,
            'assignPublicIp' : 'DISABLED'
        }
        },
        overrides = {
            'containerOverrides' : [
                {
                'name': container_name,
                'environment': runner_envs
                }
            ]
        }
    )

    #TODO - handle failures to start runner ??

    # task_arn = response['tasks'][0]['taskArn']

    # # Check task status
    # describe_task_response = ecs_client.describe_tasks(
    #     cluster=cluster_name,
    #     tasks=[task_arn]
    # )

    # task_status = describe_task_response['tasks'][0]['lastStatus']

    # if task_status == "RUNNING":
    #     print("Task was successfully spun up.")
    # else:
    #     print("Task failed to run. Status:", task_status)
    
