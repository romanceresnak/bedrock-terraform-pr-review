output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.pr_reviewer.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.pr_reviewer.arn
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.pr_reviewer.invoke_arn
}
