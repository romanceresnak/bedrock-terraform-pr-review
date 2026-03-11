output "api_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.github_webhook.id
}

output "api_endpoint" {
  description = "Endpoint URL for the webhook"
  value       = "${aws_api_gateway_stage.webhook.invoke_url}/github-webhook"
}

output "execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.github_webhook.execution_arn
}

output "stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.webhook.stage_name
}
