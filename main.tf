terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Secrets Manager Module
module "secrets" {
  source = "./modules/secrets"

  project_name = var.project_name
  github_token = var.github_token

  tags = local.common_tags
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  project_name              = var.project_name
  bedrock_model_arn         = "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.bedrock_model_id}"
  github_token_secret_arn   = module.secrets.secret_arn

  tags = local.common_tags

  depends_on = [module.secrets]
}

# Lambda Module
module "lambda" {
  source = "./modules/lambda"

  project_name                = var.project_name
  lambda_zip_path             = var.lambda_zip_path
  lambda_role_arn             = module.iam.lambda_role_arn
  github_token_secret_name    = module.secrets.secret_name
  bedrock_model_id            = var.bedrock_model_id
  aws_region                  = var.aws_region
  log_retention_days          = var.log_retention_days

  tags = local.common_tags

  depends_on = [module.iam, module.secrets]
}

# API Gateway Module
module "api_gateway" {
  source = "./modules/api_gateway"

  project_name      = var.project_name
  lambda_invoke_arn = module.lambda.invoke_arn
  stage_name        = var.environment

  tags = local.common_tags

  depends_on = [module.lambda]
}

# Lambda Permission for API Gateway (to break circular dependency)
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.execution_arn}/*/*"

  depends_on = [module.lambda, module.api_gateway]
}

# Local values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
