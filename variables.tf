variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "bedrock-pr-review"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "bedrock_model_id" {
  description = "Bedrock model ID to use for PR reviews"
  type        = string
  default     = "anthropic.claude-3-haiku-20240307-v1:0"
}

variable "lambda_zip_path" {
  description = "Path to the Lambda deployment package (ZIP file)"
  type        = string
  default     = "./lambda_deployment.zip"
}

variable "github_token" {
  description = "GitHub Personal Access Token (leave empty to set manually later)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
}
