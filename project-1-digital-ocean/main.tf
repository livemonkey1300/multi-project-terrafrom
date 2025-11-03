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
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
  
  # Ensure at least one of each character type
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = 1
}

# Generate a database password (example)
resource "random_password" "database_password" {
  length  = 20
  special = true
  upper   = true
  lower   = true
  numeric = true
  
  # Exclude confusing characters
  override_special = "!#$%&*()-_=+[]{}<>:?"
  
  # Add lifecycle to prevent accidental replacement
  lifecycle {
    ignore_changes = [length]
  }
}

# Generate an API key (example)
resource "random_password" "api_key" {
  length  = 32
  special = false  # Only alphanumeric for API keys
  upper   = true
  lower   = true
  numeric = true
}