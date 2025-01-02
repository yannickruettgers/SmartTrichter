variable "aws_region" {
  description = "The AWS region to deploy resources to."
  type        = string
  default     = "us-east-1"
}

variable "github_org_or_user" {
  description = "GitHub organization or username."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
}

variable "allowed_actions" {
  description = "List of allowed actions for the IAM policy."
  type        = list(string)
  default     = ["s3:*"]
}

variable "allowed_resources" {
  description = "List of allowed resources for the IAM policy."
  type        = list(string)
  default     = ["*"]
}