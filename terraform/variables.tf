variable "region" {
  default = "ap-south-2"
}

variable "ecr_repo" {
  description = "Full ECR repository URI including image tag, e.g., 055013504553.dkr.ecr.ap-south-2.amazonaws.com/strapi:latest"
  type        = string
}
