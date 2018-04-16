from __future__ import print_function

import os
import json
import urllib
import boto3

print('Loading function')

s3 = boto3.client('s3')

def lambda_handler(event, context):
    #print("Received event: " + json.dumps(event, indent=2))

    # Get the object from the event and show its content type
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.unquote_plus(event['Records'][0]['s3']['object']['key'].encode('utf8'))
    sqs = boto3.client('sqs')
    sqs_url = "https://sqs.us-east-1.amazonaws.com/146514670037/my-sqs"
    try:
        response = s3.get_object(Bucket=bucket, Key=key)
        print("CONTENT TYPE: " + response['ContentType'])
        sqs.send_message(
            MessageBody = "KEY:" + key + ", CONTENT TYPE:" + response['ContentType'],
            QueueUrl = os.environ['SQS_URL'],
            DelaySeconds = 0
        )
        return response['ContentType']
    except Exception as e:
        print(e)
        print('Error getting object {} from bucket {}. Make sure they exist and your bucket is in the same region as this function.'.format(key, bucket))
        raise e

