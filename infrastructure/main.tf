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

# IAM Role that the EC2 instance will assume
data "aws_iam_role" "app_role" {
  name = "App_EC2_Instance_Role"
}

# Instance Profile (required to assign the Role to the EC2 instance)
data "aws_iam_instance_profile" "app_profile" {
  name = "App_EC2_Instance_Profile"
}

# --- 2. Security Group (Firewall) ---

data "aws_security_group" "app_sg" {
  name = "app-server-sg"
}

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