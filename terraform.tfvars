# Global Terraform Variables
# This file contains variables used across all environments

# Common tags to be applied to all resources
common_tags = {
  Project     = "multi-project-terraform"
  ManagedBy   = "terraform"
  Owner       = "devops-team"
}

# AWS Region (can be overridden per environment)
aws_region = "us-east-1"

# Project name
project_name = "multi-project"

# Default instance type (can be overridden per environment)
default_instance_type = "t3.micro"