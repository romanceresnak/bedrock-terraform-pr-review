# Architektúra Riešenia

## Prehľad

Tento projekt implementuje plne automatizovaný systém na review GitHub Pull Requestov pomocou AWS Bedrock a Claude 3.5 Sonnet AI modelu.

## Diagram toku

```
┌──────────────┐
│   GitHub     │
│  Repository  │
└──────┬───────┘
       │ PR Event (opened/synchronize)
       │
       ▼
┌──────────────────────┐
│  GitHub Webhook      │
│  (POST /github-webhook)│
└──────┬───────────────┘
       │ HTTP POST
       │
       ▼
┌─────────────────────────────┐
│      API Gateway            │
│  (REST API)                 │
│  POST /github-webhook       │
└──────┬──────────────────────┘
       │ Invoke
       │
       ▼
┌─────────────────────────────┐
│     Lambda Function         │
│  - Parse webhook payload    │
│  - Get GitHub token         │◄────────┐
│  - Fetch PR diff           │         │
│  - Call Bedrock            │         │
│  - Post review comment     │         │
└──────┬──┬───────────────────┘        │
       │  │                            │
       │  └──────────────────┐         │
       │                     │         │
       ▼                     ▼         │
┌──────────────┐   ┌──────────────────┴─────┐
│   Bedrock    │   │   Secrets Manager      │
│   Claude     │   │   (GitHub Token)       │
│   3.5 Sonnet │   └────────────────────────┘
└──────┬───────┘
       │ AI Review
       │
       ▼
┌──────────────────────────────┐
│  Lambda Response             │
│  (Review comment text)       │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  GitHub API                  │
│  POST /repos/.../comments    │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  PR Comment                  │
│  (AI-generated review)       │
└──────────────────────────────┘
```

## AWS Komponenty

### 1. API Gateway (REST API)

**Účel**: Príjem GitHub webhook eventov

**Konfigurácia**:
- Endpoint: `POST /github-webhook`
- Stage: `prod`
- Integration: Lambda Proxy
- Authorization: NONE (GitHub webhook)

**Modularizácia**: `modules/api_gateway/`

### 2. Lambda Function

**Účel**: Orchestrácia review procesu

**Runtime**: Python 3.11
**Timeout**: 300s (5 min)
**Memory**: 512 MB

**Environment Variables**:
- `GITHUB_TOKEN_SECRET_NAME` - Secrets Manager secret name
- `BEDROCK_MODEL_ID` - Claude model ID
- `AWS_REGION_BEDROCK` - AWS region

**Proces**:
1. Parse webhook payload
2. Validate event type (only `opened` / `synchronize`)
3. Retrieve GitHub token from Secrets Manager
4. Fetch PR diff via GitHub API
5. Send diff to Bedrock Claude
6. Post AI-generated review to PR

**Modularizácia**: `modules/lambda/`

### 3. AWS Bedrock

**Model**: Claude 3.5 Sonnet v2
**Model ID**: `anthropic.claude-3-5-sonnet-20241022-v2:0`

**Parametre**:
- Temperature: 0.3 (konzistentné odpovede)
- Max tokens: 4000
- API: `bedrock-runtime.invoke_model()`

**Prompt**: Obsahuje PR title, description a diff

### 4. Secrets Manager

**Účel**: Bezpečné uloženie GitHub Personal Access Token

**Secret Format**:
```json
{
  "token": "ghp_xxxxxxxxxxxxx"
}
```

**IAM Access**: Len Lambda execution role

**Modularizácia**: `modules/secrets/`

### 5. IAM

**Lambda Execution Role** s policies:

1. **CloudWatch Logs**
   ```
   logs:CreateLogGroup
   logs:CreateLogStream
   logs:PutLogEvents
   ```

2. **Bedrock**
   ```
   bedrock:InvokeModel
   bedrock:InvokeModelWithResponseStream
   ```

3. **Secrets Manager**
   ```
   secretsmanager:GetSecretValue
   ```

**Modularizácia**: `modules/iam/`

### 6. CloudWatch Logs

**Log Groups**:
- `/aws/lambda/bedrock-pr-review-pr-reviewer` - Lambda logs
- `/aws/apigateway/bedrock-pr-review-api` - API Gateway logs

**Retention**: 7 dní (konfigurovateľné)

## Bezpečnosť

### Princípy

1. ✅ **Least Privilege**: IAM role s minimálnymi oprávneniami
2. ✅ **Secrets Management**: GitHub token v Secrets Manager
3. ✅ **Encryption**: Secrets encrypted at rest (AWS managed key)
4. ✅ **HTTPS Only**: Všetka komunikácia cez HTTPS
5. ✅ **Audit Logging**: CloudWatch logs pre všetky akcie

### Tok autentifikácie

```
GitHub → API Gateway (public) → Lambda (private)
                                    ↓
                              Secrets Manager
                                    ↓
                              GitHub API (authenticated)
```

## Škálovateľnosť

### Lambda Concurrency

- **Default**: Až 1000 concurrent executions
- **Reserved**: Možno nastaviť pre konzistentný výkon
- **Cold start**: ~2-3s (Python runtime)

### API Gateway Limits

- **Rate**: 10,000 requests/second
- **Burst**: 5,000 requests
- **Throttling**: Konfigurovateľné usage plans

### Bedrock Limits

- **Tokens/min**: Závisí od modelu (Claude 3.5: ~100,000 TPM)
- **Requests/min**: ~60-100 RPM

## Monitorovanie

### Metriky

1. **Lambda**:
   - Invocations
   - Duration
   - Errors
   - Throttles

2. **API Gateway**:
   - 4XX errors
   - 5XX errors
   - Latency
   - Count

3. **Bedrock**:
   - Model invocations
   - Input/Output tokens
   - Errors

### Alarmy (odporúčané)

```hcl
# Lambda errors > 5%
# API Gateway 5XX > 1%
# Lambda duration > 30s (P99)
```

## Cost Optimization

### Stratégie

1. **Lambda**: Optimalizácia memory/timeout
2. **CloudWatch**: Kratšia retention (7 dní)
3. **Bedrock**: Rate limiting pre high-volume repos
4. **API Gateway**: Edge optimized (cache)

### Príklad nákladov

**100 PRs/mesiac**:
- Lambda: $0.20
- API Gateway: $0.01
- Bedrock: $15-30
- Secrets Manager: $0.40
- CloudWatch: $0.50

**Total**: ~$16-31/mesiac

## Rozšírenia

### Možné vylepšenia

1. **DynamoDB** - Cache pre častých contributors
2. **SQS** - Queue pre rate limiting
3. **EventBridge** - Routing pre rôzne event types
4. **S3** - Archív reviews
5. **SNS** - Notifikácie (Slack/Teams)
6. **X-Ray** - Distributed tracing

### Multi-region deployment

```
┌──────────┐     ┌──────────┐
│ us-east-1│     │ eu-west-1│
│  Primary │────▶│  Failover│
└──────────┘     └──────────┘
      │                │
      ▼                ▼
  Route 53 Health Check
```

## Terraform Moduly

### Modul Dependency Graph

```
main.tf
├── module.secrets
│   └── aws_secretsmanager_secret
├── module.iam
│   ├── aws_iam_role
│   └── aws_iam_role_policy (x3)
├── module.lambda
│   ├── aws_lambda_function
│   ├── aws_cloudwatch_log_group
│   └── aws_lambda_permission
└── module.api_gateway
    ├── aws_api_gateway_rest_api
    ├── aws_api_gateway_resource
    ├── aws_api_gateway_method
    ├── aws_api_gateway_integration
    ├── aws_api_gateway_deployment
    └── aws_api_gateway_stage
```

### Výhody modulárnej architektúry

1. ✅ **Reusability**: Moduly použiteľné v iných projektoch
2. ✅ **Testability**: Jednotlivé moduly testovateľné samostatne
3. ✅ **Maintainability**: Ľahšia údržba a updates
4. ✅ **Separation of Concerns**: Každý modul má jednu zodpovednosť
5. ✅ **Version Control**: Moduly môžu mať vlastné verzie

---

**Otázky?** Vytvor issue v GitHub repository.
