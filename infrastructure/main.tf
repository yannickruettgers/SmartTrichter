# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket = "trichter-tf-state-bucket"

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "Dev"
  }
}

# Separate Versioning Configuration for S3 Bucket
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

# DynamoDB Table for Terraform State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-state-locks"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1  # 1 RCU, within free tier
  write_capacity = 1  # 1 WCU, within free tier

  hash_key       = "LockID"  # Partition key for the table
  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "Dev"
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # GitHub's fixed thumbprint
}

resource "aws_iam_role" "github_actions_role" {
  name = "GitHubActionsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" : "repo:${var.org_or_user}/${var.repo}:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "github_actions_policy" {
  name   = "GitHubActionsPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = var.allowed_actions,
        Resource = var.allowed_resources
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_policy_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = "$var.environment}-trichter-app-bucket"
  tags = {
    Name        = "Trichter App Bucket"
    Environment = var.environment
  }
}