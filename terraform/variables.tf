# variables.tf

variable "region" {
  default = "ap-south-2"
}

variable "ecr_repo" {
  description = "Full ECR repository URI including image tag"
  type        = string
}
