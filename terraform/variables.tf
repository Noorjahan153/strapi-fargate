variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment (dev, prod, test)"
  type        = string
  default     = "dev"
}

variable "ecr_repo" {
  description = "ECR repository URI for the Strapi image"
  type        = string
}
