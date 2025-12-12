variable "aws_region" {
  description = "The AWS region to deploy into"
  type        = string
  default     = "us-west-2"
}

variable "ecr_image_uri" {
  description = "The full URI of the Docker image in ECR (e.g., 123456789012.dkr.ecr.us-east-1.amazonaws.com/quotes-repo:latest)"
  type        = string
}

variable "ecr_registry_uri" {
  description = "The full URI of the ECR registry (e.g., 123456789012.dkr.ecr.us-east-1.amazonaws.com)"
  type        = string
}