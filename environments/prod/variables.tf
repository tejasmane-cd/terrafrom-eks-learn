variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eks-learn-prod"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.20.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "endpoint_public_access_cidrs" {
  description = "CIDRs allowed to access the public EKS API endpoint (empty list disables public access when combined with endpoint_public_access=false)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Extra resource tags"
  type        = map(string)
  default     = {}
}
