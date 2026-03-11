# API Gateway REST API
resource "aws_api_gateway_rest_api" "github_webhook" {
  name        = "${var.project_name}-api"
  description = "API Gateway for GitHub webhook PR reviews"

  tags = var.tags
}

# API Gateway Resource
resource "aws_api_gateway_resource" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook.id
  parent_id   = aws_api_gateway_rest_api.github_webhook.root_resource_id
  path_part   = "github-webhook"
}

# API Gateway Method - POST
resource "aws_api_gateway_method" "webhook_post" {
  rest_api_id   = aws_api_gateway_rest_api.github_webhook.id
  resource_id   = aws_api_gateway_resource.webhook.id
  http_method   = "POST"
  authorization = "NONE"
}

# Lambda Integration
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.github_webhook.id
  resource_id             = aws_api_gateway_resource.webhook.id
  http_method             = aws_api_gateway_method.webhook_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.webhook.id,
      aws_api_gateway_method.webhook_post.id,
      aws_api_gateway_integration.lambda.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.webhook_post,
    aws_api_gateway_integration.lambda
  ]
}

# API Gateway Stage
resource "aws_api_gateway_stage" "webhook" {
  deployment_id = aws_api_gateway_deployment.webhook.id
  rest_api_id   = aws_api_gateway_rest_api.github_webhook.id
  stage_name    = var.stage_name

  tags = var.tags
}
