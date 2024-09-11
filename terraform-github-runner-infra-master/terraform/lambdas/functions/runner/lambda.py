
import json
import hmac
import boto3
import os
import hashlib
from aws_lambda_powertools import Logger
from runner import create_runner

labels = ['self-hosted', 'ephemeral', 'x86_64', 'linux']

logger = Logger()
def handler(event, context):

    payload = event['body']
    json_payload = json.loads(payload)
    l_headers = {k.lower(): v for k, v in event['headers'].items()}

    if json_payload['workflow_job']['status'] != 'queued':
        logger.info(f"Workflow job other than 'queued' status are ignored")
        return {
            'statusCode': 200,
            'body': 'Ignored'
        }
    

    if os.getenv('WEBHOOK_SECRET_PATH') is None:
        return {
            'body': 'WEBHOOK_SECRET_PATH environment is not set! Stop processing the webhook',
            'statusCode': 403
        }
    webhook_secret_param = os.getenv('WEBHOOK_SECRET_PATH')
    webhook_secret = get_parameter(webhook_secret_param)
    if any(item in labels for item in json_payload['workflow_job']['labels']):
        payload_encoded = payload.encode('utf-8')
        if 'x-hub-signature-256' not in l_headers:
            return {
                'body': 'x-hub-signature-256 header is missing! Stop processing the webhook. \n Please config the GitHub Webhook wit a secret !!!',
                'statusCode': 403
            }
        else:
            if verify_signature(payload_encoded, webhook_secret, l_headers['x-hub-signature-256']):
                logger.info('GitHub Webhook secret validation PASSED! Creating GitHub Actions Runners in ECS Fargate !')
                logger.info(f'GitHub Webhook Event of the Workflow Job Queued: {json.dumps(json_payload)}')
                create_runner(json_payload)
                return {
                    'statusCode': 200,
                    'body': 'Success'
                }
    else:
        logger.info(f"Workflow job labels are not in {labels} are ignored")
        return {
            'statusCode': 200,
            'body': 'Labels did not match. Job ignored'
        }
    
def verify_signature(payload_body, secret_token, signature_header):
    """Verify that the payload was sent from GitHub by validating SHA256.

    Raise and return 403 if not authorized.

    Args:
        payload_body: original request body to verify (request.body())
        secret_token: GitHub app webhook token (WEBHOOK_SECRET)
        signature_header: header received from GitHub (x-hub-signature-256)
    """
    hash_object = hmac.new(secret_token.encode('utf-8'), msg=payload_body, digestmod=hashlib.sha256)
    expected_signature = "sha256=" + hash_object.hexdigest()
    if not hmac.compare_digest(expected_signature, signature_header):
        raise ValueError("Request signatures didn't match! Stop processing the webhook.")
    else:
        return True, None
    

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