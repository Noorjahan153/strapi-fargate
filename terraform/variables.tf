variable "aws_account_id" {
  description = "AWS account ID for ECR"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-2"
}
