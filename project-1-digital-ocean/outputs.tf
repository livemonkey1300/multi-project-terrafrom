# Outputs for generated passwords
# Note: These are marked as sensitive to prevent them from being displayed in logs

output "main_password" {
  description = "The generated main password"
  value       = random_password.main_password.result
  sensitive   = true
}

output "database_password" {
  description = "The generated database password"
  value       = random_password.database_password.result
  sensitive   = true
}

output "api_key" {
  description = "The generated API key"
  value       = random_password.api_key.result
  sensitive   = true
}

# If you need to use the password in other resources, you can reference it like:
# password = random_password.main_password.result

# Example of how to store in Terraform Cloud as a sensitive variable
# You can then use terraform output to retrieve these values when needed