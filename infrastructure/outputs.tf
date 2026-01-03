output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = "https://${aws_api_gateway_rest_api.user_api.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}"
}

output "table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.users_table.name
}

output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.get_user_function.function_name
}

output "log_group_name" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.lambda_log_group.name
}