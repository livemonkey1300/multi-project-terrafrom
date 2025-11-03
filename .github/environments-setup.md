# GitHub Environments Configuration Guide

This file provides guidance on setting up GitHub environments for the Terraform pipeline.

## Required Environments

### 1. Development Environment (`dev`)
```yaml
Environment Name: dev
Protection Rules:
  - Required reviewers: 1
  - Restrict pushes to specific branches: main
  - Environment secrets: none (uses repository secrets)
```

### 2. Staging Environment (`staging`)
```yaml
Environment Name: staging
Protection Rules:
  - Required reviewers: 2
  - Restrict pushes to specific branches: main
  - Environment secrets: none (uses repository secrets)
```

### 3. Development Destroy Environment (`dev-destroy`)
```yaml
Environment Name: dev-destroy
Protection Rules:
  - Required reviewers: 2
  - Restrict pushes to specific branches: main
  - Wait timer: 5 minutes
  - Environment secrets: none (uses repository secrets)
```

### 4. Staging Destroy Environment (`staging-destroy`)
```yaml
Environment Name: staging-destroy
Protection Rules:
  - Required reviewers: 3
  - Restrict pushes to specific branches: main
  - Wait timer: 10 minutes
  - Environment secrets: none (uses repository secrets)
```

## Setup Instructions

### Via GitHub UI:
1. Go to your repository on GitHub
2. Navigate to Settings → Environments
3. Click "New environment"
4. Enter environment name
5. Configure protection rules as specified above
6. Save the environment

### Required Repository Secrets:
- `AWS_ACCESS_KEY_ID`: Your AWS access key ID
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key

### Optional Environment-Specific Secrets:
If you need different AWS credentials per environment:
- Create environment-specific secrets with the same names
- They will override repository-level secrets for that environment

## Security Best Practices

### Reviewer Requirements:
- **Dev**: 1 reviewer (for quick iteration)
- **Staging**: 2 reviewers (more critical)
- **Destroy operations**: Additional reviewers (irreversible actions)

### Wait Timers:
- Add wait timers for destroy operations to allow for last-minute cancellation
- Consider longer timers for production environments

### Branch Restrictions:
- Only allow deployments from main/master branch
- Consider allowing deployments from release branches for staging

## AWS IAM Setup

### Recommended IAM Policy:
Create separate IAM users/roles for each environment with appropriate permissions.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "vpc:*",
        "iam:*",
        "s3:*",
        "dynamodb:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalTag/Environment": "${environment}"
        }
      }
    }
  ]
}
```

### S3 Backend Permissions:
Ensure the IAM user/role has permissions for the Terraform state bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::your-terraform-state-bucket",
        "arn:aws:s3:::your-terraform-state-bucket/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-state-lock"
    }
  ]
}
```