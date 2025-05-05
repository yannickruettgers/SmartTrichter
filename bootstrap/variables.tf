variable "aws_region" {
  description = "The AWS region to deploy resources to."
  type        = string
  default     = "eu-central-1"
}

variable "org_or_user" {
  type        = string
  description = "GitHub organization or username"
}

variable "repo" {
  type        = string
  description = "GitHub repository name"
}

variable "allowed_actions" {
  type        = list(string)
  description = "IAM actions allowed to the GitHub role"
  default     = ["s3:*", "lambda:*", "apigateway:*", "dynamodb:*", "cognito-idp:*"]
}

variable "allowed_resources" {
  type        = list(string)
  description = "Resources allowed for GitHub Actions"
  default     = ["*"]
}
