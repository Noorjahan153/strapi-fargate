# variables.tf

# AWS Account ID (12-digit number)
variable "aws_account_id" {
  description = "AWS Account ID for ECR repository"
  type        = string
}

# AWS Region (optional, default to Hyderabad)
variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-south-2"
}
