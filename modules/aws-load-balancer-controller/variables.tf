variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster runs"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "chart_version" {
  description = "Pinned Helm chart version for aws-load-balancer-controller"
  type        = string
  default     = "1.11.0"
}

variable "ingress_class_is_default" {
  description = "Mark the alb IngressClass as the cluster default"
  type        = bool
  default     = false
}

variable "create_example_ingress" {
  description = "Deploy a small demo app and Ingress to learn ALB provisioning"
  type        = bool
  default     = true
}

variable "example_namespace" {
  description = "Namespace for the demo Ingress workload"
  type        = string
  default     = "alb-demo"
}

variable "example_ingress_scheme" {
  description = "ALB scheme for the demo Ingress (internet-facing or internal)"
  type        = string
  default     = "internet-facing"

  validation {
    condition     = contains(["internet-facing", "internal"], var.example_ingress_scheme)
    error_message = "example_ingress_scheme must be internet-facing or internal."
  }
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
