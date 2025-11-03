# Terraform variables for password generation
# You can customize these values for your specific needs

# Password configuration
password_length          = 16
database_password_length = 24
api_key_length          = 32
include_special_chars   = true

# Environment
environment = "dev"

# Example values for different environments:
# 
# For Development:
# environment = "dev"
# password_length = 12
# 
# For Production:
# environment = "prod"  
# password_length = 24
# database_password_length = 32