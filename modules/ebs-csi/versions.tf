terraform {
  required_version = ">= 1.10.0, < 1.17.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.61.0"
    }
    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = "~> 2.38.0"
      configuration_aliases = [kubernetes]
    }
  }
}
