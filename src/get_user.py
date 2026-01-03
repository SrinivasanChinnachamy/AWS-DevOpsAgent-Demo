import boto3
import json
import os
import logging

# Configure logging for CloudWatch
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# ISSUE: No retry configuration - this will cause throttling errors
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

def lambda_handler(event, context):
    # Log the incoming request
    logger.info(f"Processing request for user lookup")
    logger.info(f"Request ID: {context.aws_request_id}")
    
    try:
        # Get table name from environment
        table_name = os.environ['TABLE_NAME']
        table = dynamodb.Table(table_name)
        
        # Extract userId from path parameters
        user_id = event['pathParameters']['userId']
        logger.info(f"Looking up user: {user_id}")
        
        # ISSUE: No exponential backoff for DynamoDB throttling
        # ISSUE: No circuit breaker pattern
        response = table.get_item(
            Key={'userId': user_id}
        )
        
        # Return user data or empty if not found
        user_data = response.get('Item', {})
        
        if user_data:
            logger.info(f"User found: {user_id}")
        else:
            logger.info(f"User not found: {user_id}")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(user_data, default=str)
        }
        
    except Exception as e:
        # ISSUE: Generic exception handling - doesn't distinguish throttling
        # This will create clear error logs for DevOps Agent to analyze
        logger.error(f"Error processing request: {str(e)}")
        logger.error(f"Error type: {type(e).__name__}")
        logger.error(f"Request ID: {context.aws_request_id}")
        
        # Log additional context for DevOps Agent analysis
        if "ProvisionedThroughputExceededException" in str(e):
            logger.error("DynamoDB throttling detected - no retry logic configured")
        
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'requestId': context.aws_request_id
            })
        }

# ISSUE: No connection pooling
# ISSUE: No caching mechanism
# ISSUE: No input validation
# ISSUE: No custom CloudWatch metrics