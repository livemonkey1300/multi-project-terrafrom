# Multi-Directory Terraform GitHub Actions Pipeline

This repository contains a comprehensive GitHub Actions pipeline for managing Terraform infrastructure across multiple directories and environments.

## 🏗 Architecture

The repository is structured to support multiple environments (dev, staging) with separate modules (network, app):

```
terraform/
├── environments/
│   ├── dev/
│   │   ├── network/    # VPC, subnets, gateways
│   │   └── app/        # Load balancer, auto scaling
│   └── staging/
│       ├── network/    # VPC, subnets, gateways
│       └── app/        # Load balancer, auto scaling
└── terraform.tfvars   # Global variables
```

## 🚀 Features

### Pipeline Capabilities
- **Multi-Directory Support**: Automatically detects and processes multiple Terraform directories
- **Environment Management**: Supports dev, staging, and production environments
- **Module-Based**: Separate network and application modules for better organization
- **Multiple Actions**: Support for `plan`, `apply`, and `destroy` operations
- **Matrix Strategy**: Parallel execution across environments and modules
- **State Management**: Integrated with S3 backend for remote state storage
- **Security**: Environment protection for sensitive operations

### Supported Operations

1. **Plan** 🗂️
   - Automatic on PR creation
   - Manual trigger with specific environment/module selection
   - Plan artifacts are stored for later use

2. **Apply** ✅
   - Manual trigger only
   - Requires environment approval
   - Uses previously generated plans

3. **Destroy** 🔥
   - Manual trigger only
   - Requires special environment approval (`{env}-destroy`)
   - Generates destroy plan before execution

## 📋 Prerequisites

### Required Secrets
Configure the following secrets in your GitHub repository:

```bash
AWS_ACCESS_KEY_ID      # AWS Access Key
AWS_SECRET_ACCESS_KEY  # AWS Secret Key
```

### S3 Backend Setup
Update the S3 backend configuration in the Terraform files:

```hcl
backend "s3" {
  bucket = "your-terraform-state-bucket"
  key    = "{environment}/{module}/terraform.tfstate"
  region = "us-east-1"
}
```

### Environment Protection
Configure environment protection rules in GitHub:
- `dev` environment: For apply operations
- `staging` environment: For apply operations  
- `dev-destroy` environment: For destroy operations
- `staging-destroy` environment: For destroy operations

## 🎯 Usage

### Automatic Triggers

#### Pull Request
```yaml
# Triggers on PR to main branch
# - Runs terraform format check
# - Runs terraform validation
# - Generates plans for all environments and modules
```

#### Push to Main
```yaml
# Triggers on push to main branch
# - Runs plans for all environments and modules
# - Does NOT auto-apply (manual approval required)
```

### Manual Triggers

#### 1. Plan Operation
```bash
# Via GitHub UI: Actions → Terraform Multi-Directory Pipeline → Run workflow
Action: plan
Environment: dev | staging | all
Module: network | app | all
```

#### 2. Apply Operation
```bash
# Via GitHub UI: Actions → Terraform Multi-Directory Pipeline → Run workflow
Action: apply
Environment: dev | staging | all
Module: network | app | all
```

#### 3. Destroy Operation
```bash
# Via GitHub UI: Actions → Terraform Multi-Directory Pipeline → Run workflow
Action: destroy
Environment: dev | staging | all
Module: network | app | all
```

### Command Line Triggers

Using GitHub CLI:

```bash
# Plan all environments and modules
gh workflow run terraform.yml -f action=plan -f environment=all -f module=all

# Apply to dev environment, all modules
gh workflow run terraform.yml -f action=apply -f environment=dev -f module=all

# Apply to staging environment, network module only
gh workflow run terraform.yml -f action=apply -f environment=staging -f module=network

# Destroy dev environment (requires approval)
gh workflow run terraform.yml -f action=destroy -f environment=dev -f module=all
```

## 🔄 Workflow Details

### Job Dependencies
The pipeline follows this execution flow:
1. **terraform-check**: Format and validation checks
2. **plan-matrix**: Dynamic matrix generation
3. **terraform-plan**: Generate plans for selected environments/modules
4. **terraform-apply**: Apply infrastructure (manual trigger only)
5. **terraform-destroy**: Destroy infrastructure (manual trigger only)

### Matrix Generation
The pipeline dynamically generates a matrix based on:
- Selected environments (`dev`, `staging`, `all`)
- Selected modules (`network`, `app`, `all`)
- Available directory structure

### Execution Order
1. **Network First**: Network infrastructure is typically deployed first
2. **App Second**: Application infrastructure depends on network outputs
3. **Parallel Execution**: Same-level modules run in parallel where possible

## 📁 File Structure

### Core Files
- `.github/workflows/terraform.yml` - Main pipeline configuration
- `terraform.tfvars` - Global Terraform variables
- `terraform/environments/{env}/{module}/` - Environment-specific configurations

### Environment-Specific Variables
Each environment can override global variables:

```hcl
# Dev environment might use:
default_instance_type = "t3.micro"
vpc_cidr = "10.0.0.0/16"

# Staging environment might use:
default_instance_type = "t3.small" 
vpc_cidr = "10.1.0.0/16"
```

## 🛡 Security Considerations

### Environment Protection
- **Apply operations** require environment approval
- **Destroy operations** require special environment approval
- **Sensitive environments** should have restricted access

### State File Security
- State files stored in encrypted S3 bucket
- Access controlled via IAM policies
- Versioning enabled for rollback capability

### Secrets Management
- AWS credentials stored as GitHub secrets
- No hardcoded sensitive values in repository
- Use IAM roles for enhanced security

## 🔧 Customization

### Adding New Environments
1. Create directory structure: `terraform/environments/{new-env}/`
2. Copy module configurations from existing environment
3. Update environment-specific variables
4. Add environment to pipeline matrix generation

### Adding New Modules
1. Create module directory: `terraform/environments/{env}/{new-module}/`
2. Create `main.tf`, `variables.tf`, `outputs.tf`
3. Update pipeline matrix generation to include new module

## 📊 Monitoring and Debugging

### Pipeline Logs
- View detailed logs in GitHub Actions
- Each job shows Terraform plan/apply output
- Artifacts contain plan files for review

### Common Issues
1. **Backend not configured**: Update S3 backend settings
2. **Missing secrets**: Verify AWS credentials in repository secrets
3. **Environment protection**: Check GitHub environment settings
4. **State lock**: May need to force-unlock stuck state files

## 🚀 Best Practices

### Development Workflow
1. Create feature branch
2. Make infrastructure changes
3. Open PR (triggers automatic plan)
4. Review plan outputs in PR comments
5. Merge to main
6. Manually trigger apply for desired environment

### State Management
- Always use remote state (S3)
- Enable state file versioning
- Implement state locking (DynamoDB)
- Regular state file backups

### Module Organization
- Keep modules focused and reusable
- Use consistent naming conventions
- Document module inputs/outputs
- Version your modules

---

**Note**: This pipeline is designed for AWS infrastructure. Modify the provider and resource configurations for other cloud providers.
