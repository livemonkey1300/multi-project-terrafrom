# Variables for password configuration

variable "password_length" {
  description = "Length of the main password"
  type        = number
  default     = 16
  
  validation {
    condition     = var.password_length >= 8 && var.password_length <= 128
    error_message = "Password length must be between 8 and 128 characters."
  }
}

variable "database_password_length" {
  description = "Length of the database password"
  type        = number
  default     = 20
  
  validation {
    condition     = var.database_password_length >= 12 && var.database_password_length <= 128
    error_message = "Database password length must be between 12 and 128 characters."
  }
}

variable "api_key_length" {
  description = "Length of the API key"
  type        = number
  default     = 32
  
  validation {
    condition     = var.api_key_length >= 16 && var.api_key_length <= 128
    error_message = "API key length must be between 16 and 128 characters."
  }
}

variable "include_special_chars" {
  description = "Whether to include special characters in passwords"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}