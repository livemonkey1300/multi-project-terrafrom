# Outputs for generated passwords and keys
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

output "session_id" {
  description = "Generated UUID for session identification"
  value       = random_uuid.session_id.result
}

output "resource_suffix" {
  description = "Random string for resource naming"
  value       = random_string.resource_suffix.result
}

# Password lengths for reference (not sensitive)


# If you need to use the password in other resources, you can reference it like:
# password = random_password.main_password.result

# Example of how to retrieve passwords using Terraform CLI:
# terraform output -raw main_password
# terraform output -raw database_password
# terraform output -raw api_key