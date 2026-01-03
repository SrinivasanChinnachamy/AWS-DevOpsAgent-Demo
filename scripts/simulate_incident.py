#!/usr/bin/env python3
import boto3
import concurrent.futures
import json

# Just trigger the incident - let DevOps Agent investigate
lambda_client = boto3.client('lambda')
function_name = 'demo-get-user-function'  # Your function name

with concurrent.futures.ThreadPoolExecutor(max_workers=50) as executor:
    list(executor.map(
        lambda i: lambda_client.invoke(
            FunctionName=function_name,
            Payload=json.dumps({'pathParameters': {'userId': f'user{i}'}})
        ), 
        range(100)
    ))

print("Incident triggered - check DevOps Agent")
