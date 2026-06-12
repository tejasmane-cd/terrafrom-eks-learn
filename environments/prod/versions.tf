terraform {
  required_version = ">= 1.5.0"

  # Remote backend is strongly recommended for prod to prevent state loss and
  # enable state locking. Uncomment and fill in your bucket/table before first apply.
  # Create the bucket and table once with: aws s3 mb s3://<bucket> and
  # aws dynamodb create-table --table-name terraform-state-lock \
  #   --attribute-definitions AttributeName=LockID,AttributeType=S \
  #   --key-schema AttributeName=LockID,KeyType=HASH \
  #   --billing-mode PAY_PER_REQUEST
  #
  # backend "s3" {
  #   bucket         = "your-tf-state-bucket"
  #   key            = "eks-learn/prod/terraform.tfstate"
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
