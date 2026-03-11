# AWS Bedrock GitHub PR Review Automation

Automated GitHub Pull Request review system using AWS Bedrock Claude AI with fully modular Terraform infrastructure.

## Architecture

```
GitHub Webhook → API Gateway → Lambda → Bedrock Claude → GitHub PR Comment
                                  ↓
                          Secrets Manager (GitHub Token)
```

## Components

- **API Gateway** - REST API endpoint for GitHub webhook (`POST /github-webhook`)
- **Lambda Function** - Process webhook events and orchestrate review workflow
- **AWS Bedrock** - Claude 3 Haiku for AI-powered code reviews
- **Secrets Manager** - Secure storage for GitHub Personal Access Token
- **IAM Roles & Policies** - Least privilege access permissions
- **CloudWatch Logs** - Logging and monitoring

## Quick Start

### Prerequisites

1. AWS Account with access to:
   - AWS Bedrock (Claude 3 Haiku enabled)
   - Lambda, API Gateway, Secrets Manager, IAM
2. Terraform >= 1.0
3. AWS CLI configured
4. GitHub Personal Access Token with `repo` and `write:discussion` permissions

### Deployment

```bash
# 1. Clone repository
git clone https://github.com/romanceresnak/bedrock-terraform-pr-review.git
cd bedrock-terraform-pr-review

# 2. Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

# 3. Build Lambda deployment package
./build_lambda.sh

# 4. Deploy infrastructure
terraform init
terraform plan
terraform apply

# 5. Set GitHub token in Secrets Manager
aws secretsmanager put-secret-value \
  --secret-id bedrock-pr-review-github-token \
  --secret-string '{"token":"ghp_YOUR_GITHUB_TOKEN"}' \
  --region eu-west-1

# 6. Get webhook URL
terraform output api_gateway_endpoint
```

### Configure GitHub Webhook

1. Go to your GitHub repository
2. **Settings** → **Webhooks** → **Add webhook**
3. Configure:
   - **Payload URL**: [Output from step 6]
   - **Content type**: `application/json`
   - **Events**: Select "Pull requests" only
   - **Active**: ✓
4. Save webhook

### Test

Create a Pull Request in your repository and wait 10-30 seconds for the AI-generated review comment!

## Module Structure

```
.
├── modules/
│   ├── api_gateway/     # API Gateway REST API
│   ├── lambda/          # Lambda function
│   ├── iam/             # IAM roles and policies
│   └── secrets/         # Secrets Manager
├── lambda_code/
│   ├── lambda_function.py
│   └── requirements.txt
├── main.tf
├── variables.tf
├── outputs.tf
└── build_lambda.sh
```

## Configuration

### Important: Bedrock Model Selection

For **eu-west-1** region, use Claude 3 Haiku:
```hcl
bedrock_model_id = "anthropic.claude-3-haiku-20240307-v1:0"
```

For **us-east-1** region, you can use newer models (check availability):
```bash
aws bedrock list-foundation-models --region us-east-1 --by-provider anthropic
```

### Terraform Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `project_name` | Project name | `bedrock-pr-review` |
| `environment` | Environment | `prod` |
| `bedrock_model_id` | Bedrock model ID | `anthropic.claude-3-haiku-20240307-v1:0` |
| `lambda_zip_path` | Lambda package path | `./lambda_deployment.zip` |
| `log_retention_days` | CloudWatch log retention | `7` |

## Monitoring

### View Lambda Logs

```bash
aws logs tail /aws/lambda/bedrock-pr-review-pr-reviewer --follow --region eu-west-1
```

### Check Webhook Deliveries

GitHub Repository → Settings → Webhooks → Recent Deliveries

## Costs

Estimated monthly costs for 100 PRs:

- Lambda: ~$0.20
- API Gateway: ~$0.01
- Bedrock (Claude 3 Haiku): ~$5-10
- Secrets Manager: $0.40
- CloudWatch Logs: ~$0.50

**Total**: ~$6-11/month

## Cleanup

```bash
# Destroy all infrastructure
terraform destroy

# Delete secret (if needed)
aws secretsmanager delete-secret \
  --secret-id bedrock-pr-review-github-token \
  --force-delete-without-recovery \
  --region eu-west-1
```

## Troubleshooting

### Lambda Timeout
Increase timeout in `modules/lambda/main.tf`:
```hcl
timeout = 300  # seconds
```

### Bedrock Model Error
Check available models:
```bash
aws bedrock list-foundation-models --region eu-west-1 --by-provider anthropic
```

### Webhook Not Triggering
1. Check webhook deliveries in GitHub
2. Verify API Gateway endpoint URL
3. Check Lambda logs for errors

## Architecture Details

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture documentation.

## License

MIT

## Author

Roman Ceresnak (romanceresnak@windowslive.com)
