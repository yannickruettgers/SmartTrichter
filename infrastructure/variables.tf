# file: infrastructure/variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources to."
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "The environment to deploy resources to."
  type        = string
  default     = "dev"
}