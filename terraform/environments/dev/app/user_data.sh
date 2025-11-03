#!/bin/bash
yum update -y
yum install -y httpd

systemctl start httpd
systemctl enable httpd

# Create a simple index.html
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Multi-Project Terraform - ${environment}</title>
</head>
<body>
    <h1>Welcome to ${environment} Environment</h1>
    <p>This is a sample application deployed via Terraform</p>
    <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
    <p>Environment: ${environment}</p>
</body>
</html>
EOF

# Start the web server
systemctl restart httpd