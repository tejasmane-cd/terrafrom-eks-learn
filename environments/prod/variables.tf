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
  default     = "1.36"
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

variable "ebs_csi_addon_version" {
  description = "Pinned aws-ebs-csi-driver EKS add-on version"
  type        = string
  default     = "v1.65.0-eksbuild.1"
}

variable "aws_load_balancer_controller_chart_version" {
  description = "Pinned Helm chart version for AWS Load Balancer Controller"
  type        = string
  default     = "1.11.0"
}

variable "create_example_ingress" {
  description = "Deploy a demo app and Ingress to exercise ALB provisioning"
  type        = bool
  default     = false
}

variable "example_ingress_scheme" {
  description = "ALB scheme for the demo Ingress"
  type        = string
  default     = "internal"
}
