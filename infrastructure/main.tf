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

# Lambda Function for User Creation
resource "aws_lambda_function" "user_creation_function" {
  function_name = "${var.environment}-user-creation-function"
  runtime       = "nodejs18.x"
  handler       = "user.handler"
  role          = aws_iam_role.lambda_execution_role.arn
  filename      = var.user_creation_lambda_package

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = {
    Name        = "User Creation Lambda Function"
    Environment = var.environment
  }
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.environment}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for Lambda Execution
resource "aws_iam_policy" "lambda_execution_policy" {
  name   = "${var.environment}-lambda-execution-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach Policy to Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_execution_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}

# API Gateway
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.environment}-http-api"
  protocol_type = "HTTP"

  tags = {
    Name        = "HTTP API Gateway"
    Environment = var.environment
  }
}

# API Gateway Integration for User Creation Lambda
resource "aws_apigatewayv2_integration" "user_creation_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.user_creation_function.invoke_arn
}

# API Gateway Route for /user Endpoint
resource "aws_apigatewayv2_route" "user_creation_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /user"

  target = "integrations/${aws_apigatewayv2_integration.user_creation_integration.id}"
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
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

# API Gateway Authorizer for Cognito
resource "aws_apigatewayv2_authorizer" "cognito_authorizer" {
  api_id       = aws_apigatewayv2_api.http_api.id
  name         = "${var.environment}-cognito-authorizer"
  authorizer_type = "JWT"

  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.user_pool_client.id]
    issuer   = aws_cognito_user_pool.user_pool.endpoint
  }
}