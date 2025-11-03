# Terraform Backend Configuration Examples

This directory contains example backend configuration files for different environments.

## S3 Backend Configuration

### Development Environment
```hcl
# backend-config-dev.hcl
bucket         = "your-terraform-state-bucket"
key            = "dev/network/terraform.tfstate"  # Update per module
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock"

# Optional: Profile-based authentication
# profile = "terraform-dev"

# Optional: Role-based authentication
# role_arn = "arn:aws:iam::123456789012:role/TerraformRole"
```

### Staging Environment
```hcl
# backend-config-staging.hcl
bucket         = "your-terraform-state-bucket"
key            = "staging/network/terraform.tfstate"  # Update per module
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock"

# Optional: Profile-based authentication
# profile = "terraform-staging"

# Optional: Role-based authentication
# role_arn = "arn:aws:iam::123456789012:role/TerraformRole"
```

## Backend Initialization Commands

### Using Backend Config Files:
```bash
# For development environment - network module
terraform init -backend-config=backend-config-dev.hcl

# For staging environment - network module
terraform init -backend-config=backend-config-staging.hcl
```

### Using Command Line:
```bash
# Development
terraform init \
  -backend-config="bucket=your-terraform-state-bucket" \
  -backend-config="key=dev/network/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=terraform-state-lock"

# Staging
terraform init \
  -backend-config="bucket=your-terraform-state-bucket" \
  -backend-config="key=staging/network/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=terraform-state-lock"
```

## S3 Bucket Setup

### Create State Bucket:
```bash
# Create the S3 bucket for state storage
aws s3 mb s3://your-terraform-state-bucket --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket your-terraform-state-bucket \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### Create DynamoDB Table for Locking:
```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

## Directory-Specific Backend Configuration

Each Terraform module should use a unique state file key:

```
terraform/
├── environments/
│   ├── dev/
│   │   ├── network/     # key: dev/network/terraform.tfstate
│   │   └── app/         # key: dev/app/terraform.tfstate
│   └── staging/
│       ├── network/     # key: staging/network/terraform.tfstate
│       └── app/         # key: staging/app/terraform.tfstate
```

## Security Considerations

### Bucket Policy Example:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureConnections",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::your-terraform-state-bucket",
        "arn:aws:s3:::your-terraform-state-bucket/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    },
    {
      "Sid": "AllowTerraformAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::YOUR-ACCOUNT-ID:user/terraform-ci",
          "arn:aws:iam::YOUR-ACCOUNT-ID:role/TerraformRole"
        ]
      },
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
    }
  ]
}
```

## Migration from Local State

If you're migrating from local state to remote state:

```bash
# 1. Update your main.tf with the backend configuration
# 2. Initialize with the new backend
terraform init

# 3. Terraform will ask if you want to migrate the state
# Type 'yes' to confirm the migration
```

## Troubleshooting

### State Lock Issues:
```bash
# If state is locked and won't unlock normally
terraform force-unlock LOCK_ID

# Check DynamoDB for lock entries
aws dynamodb scan --table-name terraform-state-lock
```

### Backend Reconfiguration:
```bash
# If you need to change backend settings
terraform init -reconfigure
```

### State Backup:
```bash
# Always backup state before major operations
terraform state pull > backup.tfstate
```

## Best Practices

1. **Use separate state files** for each environment and module
2. **Enable versioning** on the S3 bucket
3. **Use state locking** with DynamoDB
4. **Encrypt state files** at rest and in transit
5. **Implement proper IAM policies** for state bucket access
6. **Regular state backups** before major changes
7. **Use consistent naming** conventions for state files