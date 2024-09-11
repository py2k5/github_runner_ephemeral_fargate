import requests
import boto3
import os
import json

def lambda_handler(event, context):
    api_id = os.getenv("API_ID")
    if not api_id:
        return {
            'statusCode': 400,
            'body': 'API_ID environment variable is not set'
        }
    # Get the IP ranges from the GitHub API
    response = requests.get("https://api.github.com/meta")
    data = response.json()
    ip_ranges = data["hooks"]

    # Add the IP ranges to api gateway resource policy
    client = boto3.client("apigateway")
    # get current resource policy
    resource_policy = client.get_rest_api(restApiId=api_id)
    policy = resource_policy["policy"]
    policy = policy.replace("\\", "") # this step is mandatory to format the string correctly

    current_policy = json.loads(policy)

    # add the new IP ranges to the current policy  

    update_required = False
    for statement in current_policy["Statement"]:
        if statement["Effect"] == "Deny" and "Condition" in statement:
            existing_ips = statement["Condition"]["NotIpAddress"]["aws:SourceIp"]
            if isinstance(existing_ips, str):
                existing_ips = existing_ips.split(",")

            # if existing ip ranges do not match, update the ranges
            if set(existing_ips) != set(ip_ranges):
                # update the policy
                update_required = True
                statement["Condition"]["NotIpAddress"]["aws:SourceIp"] = ip_ranges
                break
    
    if update_required:
        # update the policy
        try:
            client.update_rest_api(
                                    restApiId=api_id,
                                    patchOperations=[
                                        {
                                            'op': 'replace',
                                            'path': '/policy',
                                            'value': json.dumps(current_policy)
                                        },
                                    ]
                                )
            print("Policy updated successfully")
            return {
                'statusCode': 200,
                'body': 'IP ranges Update successful'
            }
        
        except Exception as e:
            print.info(f"Error updating the resource policy: {e}")
            return {
                'statusCode': 400,
                'body': f'Failed to update the resource policy; {e}'
            }
    else:
        print("No update required")
        return {
            'statusCode': 200,
            'body': 'No update required'
        }
