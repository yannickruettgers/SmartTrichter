# file: infrastructure/provider.tf

provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket         = "trichter-tf-state-bucket"
    key            = "terraform.tfstate"
    workspace_key_prefix = "env"
#    key            = "terraform/state/trichter.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}