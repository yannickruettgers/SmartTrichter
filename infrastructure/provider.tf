provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket         = "trichter-tf-state-bucket"
    key            = "terraform/state/trichter.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}