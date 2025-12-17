# --- Provider Configuration ---
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- 1. IAM Role for EC2 (Allows Docker Pull from ECR) ---

# Policy to allow ECR read-only access (required for the EC2 instance to pull the image)
#resource "aws_iam_policy" "ecr_pull" {
#  name        = "EC2_ECR_Pull_Policy"
#  description = "Allows EC2 instance to pull images from ECR"
#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Effect = "Allow"
#        Action = [
#          "ecr:GetAuthorizationToken",
#          "ecr:BatchCheckLayerAvailability",
#          "ecr:GetDownloadUrlForLayer",
#          "ecr:BatchGetImage"
#        ]
#        Resource = "*"
#      },
#    ]
#  })
#}

# IAM Policy for Bedrock
#resource "aws_iam_policy" "bedrock_invoke" {
#  name        = "EC2_Bedrock_Invoke_Policy"
#  description = "Allows the EC2 instance to invoke the Bedrock Titan model"
#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Effect = "Allow"
#        Action = [
#          "bedrock:InvokeModel"
#        ]
#        Resource = "arn:aws:bedrock:${var.aws_region}::foundation-model/amazon.titan-text-express-v1"
#      },
#    ]
#  })
#}


# IAM Role that the EC2 instance will assume
data "aws_iam_role" "app_role" {
  name = "App_EC2_Instance_Role"
}

#resource "aws_iam_role" "app_role" {
#  name = "App_EC2_Instance_Role"
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Action = "sts:AssumeRole"
#        Effect = "Allow"
#        Principal = {
#          Service = "ec2.amazonaws.com"
#        }
#      },
#    ]
#  })
#}

# Attach the ECR Pull Policy to the Role
#resource "aws_iam_role_policy_attachment" "ecr_attach" {
#  role       = aws_iam_role.app_role.name
#  policy_arn = aws_iam_policy.ecr_pull.arn
#}

# Attach the Bedrock Invoke Policy to the Role
#resource "aws_iam_role_policy_attachment" "bedrock_attach" {
#  role       = aws_iam_role.app_role.name
#  policy_arn = aws_iam_policy.bedrock_invoke.arn
#}

# Instance Profile (required to assign the Role to the EC2 instance)
data "aws_iam_instance_profile" "app_profile" {
  name = "App_EC2_Instance_Profile"
}

#resource "aws_iam_instance_profile" "app_profile" {
#  name = "App_EC2_Instance_Profile"
#  role = aws_iam_role.app_role.name
#}

# --- 2. Security Group (Firewall) ---

data "aws_security_group" "app_sg" {
  name = "app-server-sg"
}

#resource "aws_security_group" "app_sg" {
#  name        = "app-server-sg"
#  description = "Allow SSH, HTTP (Port 80)"
#
#  # Inbound SSH (from anywhere for flexibility)
#  ingress {
#    description = "SSH access"
#    from_port   = 22
#    to_port     = 22
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  # Inbound HTTP (from anywhere)
#  ingress {
#    description = "HTTP access"
#    from_port   = 80
#    to_port     = 80
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  # Outbound (allow all internet traffic)
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#}

# --- 3. EC2 Instance Definition ---

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro" # Free Tier eligible

  # The Key Pair you created earlier
  key_name = "AI-Quote-Server-key-pair"

  vpc_security_group_ids = [data.aws_security_group.app_sg.id]
  
  # Assign the ECR Pull Role
  iam_instance_profile = data.aws_iam_instance_profile.app_profile.name 

  tags = {
    Name = "CI-CD-Quote-Server"
  }

  # This script runs on first boot to install Docker and run the application container.
  user_data = <<-EOF
              #!/bin/bash
              
              # Install Docker
              sudo yum update -y
              sudo amazon-linux-extras install docker -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              
              # Install AWS CLI (for ECR login)
              sudo yum install aws-cli -y

              # ECR login, pull, and run commands
              # The EC2 instance uses its IAM role to authenticate to ECR.
              REPO_URI="${var.ecr_image_uri}"
              
              # Log in to ECR using the official command format
              sudo aws ecr get-login-password --region ${var.aws_region} | sudo docker login --username AWS --password-stdin ${var.ecr_registry_uri}
              
              # Pull the image
              sudo docker pull $${REPO_URI}
              
              # Run the new container
              sudo docker run -d \
                -p 80:5000 \
                --name quote-of-the-day \
                $${REPO_URI}
              
              EOF
}