variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "bedrock_model_arn" {
  description = "ARN of the Bedrock model to use"
  type        = string
}

variable "github_token_secret_arn" {
  description = "ARN of the Secrets Manager secret containing GitHub token"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
