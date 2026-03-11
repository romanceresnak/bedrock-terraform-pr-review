# Test PR for AI review

## Test Function

This is a test file to verify the AI PR review system works correctly.

### Expected Behavior

When this PR is created, AWS Bedrock Claude should:
1. Receive the webhook from GitHub
2. Analyze the code changes
3. Post an AI-generated review comment
4. Provide constructive feedback

### Test Code

```python
def calculate_sum(a, b):
    # Simple function to test AI review
    result = a + b
    return result

# Example usage
total = calculate_sum(5, 3)
print(f"Total: {total}")
```

This PR tests the automated review system! 🚀

## Update: Fixed Bedrock Model

Lambda is now using Claude Sonnet 4.5 (latest model available in eu-west-1).

