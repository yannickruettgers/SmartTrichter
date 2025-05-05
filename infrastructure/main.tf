# file: infrastructure/main.tf

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

resource "aws_s3_bucket" "app_bucket" {
  bucket = "$var.environment}-trichter-app-bucket"
  tags = {
    Name        = "Trichter App Bucket"
    Environment = var.environment
  }
}

# Cognito User Pool
resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.environment}-user-pool"

  tags = {
    Name        = "Cognito User Pool"
    Environment = var.environment
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "user_pool_client" {
  name         = "${var.environment}-user-pool-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id

  allowed_oauth_flows       = ["code"]
  allowed_oauth_scopes      = ["email", "openid"]
  allowed_oauth_flows_user_pool_client = true

  callback_urls = ["https://your-app-callback-url"] # Update with your app's callback URL
}
