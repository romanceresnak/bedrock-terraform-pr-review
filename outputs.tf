output "api_gateway_endpoint" {
  description = "API Gateway webhook endpoint URL"
  value       = module.api_gateway.api_endpoint
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.function_name
}

output "github_token_secret_name" {
  description = "Name of the Secrets Manager secret for GitHub token"
  value       = module.secrets.secret_name
}

output "deployment_instructions" {
  description = "Next steps for deployment"
  value = <<-EOT

    Deployment Complete! Next steps:

    1. Set GitHub Token in Secrets Manager:
       aws secretsmanager put-secret-value \
         --secret-id ${module.secrets.secret_name} \
         --secret-string '{"token":"YOUR_GITHUB_TOKEN"}' \
         --region ${var.aws_region}

    2. Configure GitHub Webhook:
       - Go to your GitHub repository
       - Settings → Webhooks → Add webhook
       - Payload URL: ${module.api_gateway.api_endpoint}
       - Content type: application/json
       - Events: Pull requests
       - Active: ✓

    3. Test the webhook by creating a test PR

  EOT
}
