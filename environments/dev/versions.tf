terraform {
  required_version = ">= 1.5.0"

  # Uncomment to store dev state remotely (recommended for team use).
  #
  # backend "s3" {
  #   bucket         = "your-tf-state-bucket"
  #   key            = "eks-learn/dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.95"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
