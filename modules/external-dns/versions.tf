terraform {
  required_version = ">= 1.10.0, < 1.17.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.61.0"
    }
    helm = {
      source                = "hashicorp/helm"
      version               = "~> 2.17.0"
      configuration_aliases = [helm]
    }
    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = "~> 2.38.0"
      configuration_aliases = [kubernetes]
    }
  }
}
