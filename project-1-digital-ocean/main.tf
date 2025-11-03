terraform { 
  cloud { 
    
    organization = "gcp-live" 

    workspaces { 
      name = "testing" 
    } 
  }

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Generate a random password
resource "random_password" "main_password" {
  length  = var.password_length
  special = var.include_special_chars
  upper   = true
  lower   = true
  numeric = true
  
  # Ensure at least one of each character type
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = var.include_special_chars ? 1 : 0
  
  # Add keepers to regenerate password when environment changes
  keepers = {
    environment = var.environment
  }
}

# Generate a database password (example)
resource "random_password" "database_password" {
  length  = var.database_password_length
  special = var.include_special_chars
  upper   = true
  lower   = true
  numeric = true
  
  # Exclude confusing characters for better compatibility
  override_special = "!#$%&*()-_=+[]{}<>:?"
  
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = var.include_special_chars ? 1 : 0
  
  # Add lifecycle to prevent accidental replacement
  lifecycle {
    ignore_changes = [length]
  }
  
  # Add keepers to regenerate password when environment changes
  keepers = {
    environment = var.environment
  }
}

# Generate an API key (example)
resource "random_password" "api_key" {
  length  = var.api_key_length
  special = false  # Only alphanumeric for API keys
  upper   = true
  lower   = true
  numeric = true
  
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  
  # Add keepers to regenerate API key when environment changes
  keepers = {
    environment = var.environment
  }
}

# Generate a UUID (alternative to password for some use cases)
resource "random_uuid" "session_id" {}

# Generate a random string (for resource naming)
resource "random_string" "resource_suffix" {
  length  = 8
  special = false
  upper   = false
  lower   = true
  numeric = true
}