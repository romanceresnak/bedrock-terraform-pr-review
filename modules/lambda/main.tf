# Lambda Function
resource "aws_lambda_function" "pr_reviewer" {
  filename         = var.lambda_zip_path
  function_name    = "${var.project_name}-pr-reviewer"
  role            = var.lambda_role_arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  runtime         = "python3.11"
  timeout         = 300
  memory_size     = 512

  environment {
    variables = {
      GITHUB_TOKEN_SECRET_NAME = var.github_token_secret_name
      BEDROCK_MODEL_ID        = var.bedrock_model_id
      AWS_REGION_BEDROCK      = var.aws_region
    }
  }

  tags = var.tags
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.pr_reviewer.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}
