# DynamoDB Table - INTENTIONALLY LOW CAPACITY
resource "aws_dynamodb_table" "users_table" {
  name           = "${var.environment}-users-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5  # ISSUE: Too low - will cause throttling
  write_capacity = 5  # ISSUE: Too low for production

  hash_key = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  # ISSUE: No auto-scaling configuration
  # ISSUE: No backup configuration
  # ISSUE: No point-in-time recovery
  # ISSUE: No encryption at rest specified

  tags = {
    Environment = var.environment
    Application = "user-api"
    Component   = "retrieve-user-api"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.environment}-user-api-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Application = "user-api"
    Component   = "retrieve-user-api"
  }
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "dynamodb-access"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"  # ISSUE: Too broad permissions
        ]
        Resource = aws_dynamodb_table.users_table.arn
      }
    ]
  })
}

# CloudWatch Logs IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_logging_policy" {
  name = "lambda-logging"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      }
    ]
  })
}

# Attach basic execution role
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch Log Group for Lambda Function
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.environment}-get-user-function"
  retention_in_days = 14  # ISSUE: Short retention for production

  tags = {
    Environment = var.environment
    Application = "user-api"
    Component   = "retrieve-user-api"
  }
}

# Lambda Function
resource "aws_lambda_function" "get_user_function" {
  filename         = "lambda_deployment.zip"
  function_name    = "${var.environment}-get-user-function"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "get_user.lambda_handler"
  runtime         = "python3.11"
  timeout         = 30  # ISSUE: Too high for DynamoDB operation
  memory_size     = 128 # ISSUE: Might be too low for Python cold starts

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.users_table.name
    }
  }

  # ISSUE: No X-Ray tracing enabled
  # ISSUE: No reserved concurrency
  # ISSUE: No dead letter queue

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy.lambda_dynamodb_policy,
    aws_iam_role_policy.lambda_logging_policy,
    aws_cloudwatch_log_group.lambda_log_group,
  ]

  tags = {
    Environment = var.environment
    Application = "user-api"
    Component   = "retrieve-user-api"
  }
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "user_api" {
  name        = "${var.environment}-user-api"
  description = "User API for DevOps Agent Demo"

  # ISSUE: No API key requirement
  # ISSUE: No throttling configuration

  tags = {
    Environment = var.environment
    Application = "user-api"
    Component   = "retrieve-user-api"
  }
}

# API Gateway Resource - /users
resource "aws_api_gateway_resource" "users_resource" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  parent_id   = aws_api_gateway_rest_api.user_api.root_resource_id
  path_part   = "users"
}

# API Gateway Resource - /users/{userId}
resource "aws_api_gateway_resource" "user_id_resource" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  parent_id   = aws_api_gateway_resource.users_resource.id
  path_part   = "{userId}"
}

# API Gateway Method - GET /users/{userId}
resource "aws_api_gateway_method" "get_user_method" {
  rest_api_id   = aws_api_gateway_rest_api.user_api.id
  resource_id   = aws_api_gateway_resource.user_id_resource.id
  http_method   = "GET"
  authorization = "NONE"  # ISSUE: No authentication

  # ISSUE: No request validation
}

# API Gateway Integration
resource "aws_api_gateway_integration" "get_user_integration" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  resource_id = aws_api_gateway_resource.user_id_resource.id
  http_method = aws_api_gateway_method.get_user_method.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.get_user_function.invoke_arn
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_user_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.user_api.execution_arn}/*/*"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_method.get_user_method,
    aws_api_gateway_integration.get_user_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.user_api.id
  stage_name  = var.environment

  # ISSUE: No stage configuration for throttling
  # ISSUE: No logging configuration
  # ISSUE: No caching configuration
}

# MISSING RESOURCES:
# - CloudWatch Alarms
# - DynamoDB Auto Scaling
# - Lambda Dead Letter Queue
# - X-Ray Tracing
# - VPC Configuration
# - WAF for API Gateway

# ISSUE: No CloudWatch alarms configured
# ISSUE: No error rate monitoring
# ISSUE: No duration monitoring
# ISSUE: No throttling monitoring