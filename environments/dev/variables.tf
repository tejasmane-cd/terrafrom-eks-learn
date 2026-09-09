variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eks-learn-dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.10.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.36"
}

variable "endpoint_public_access_cidrs" {
  description = "CIDRs allowed to access the public EKS API endpoint (e.g. your office/VPN IP: [\"1.2.3.4/32\"])"
  type        = list(string)
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
  default     = true
}

variable "example_ingress_scheme" {
  description = "ALB scheme for the demo Ingress"
  type        = string
  default     = "internet-facing"
}

variable "cert_manager_acme_email" {
  description = "Email for the Let's Encrypt ACME account used by cert-manager"
  type        = string
}

variable "cert_manager_chart_version" {
  description = "Pinned Helm chart version for cert-manager"
  type        = string
  default     = "v1.17.2"
}

variable "cert_manager_acme_solver_type" {
  description = "ACME solver for cert-manager: http01 (ALB) or dns01 (Route53)"
  type        = string
  default     = "http01"
}

variable "cert_manager_route53_hosted_zone_arns" {
  description = "Route53 zone ARNs for DNS-01 (required when cert_manager_acme_solver_type is dns01)"
  type        = list(string)
  default     = []
}

variable "cert_manager_enable_staging_issuer" {
  description = "Create a Let's Encrypt staging ClusterIssuer"
  type        = bool
  default     = true
}

variable "cert_manager_enable_production_issuer" {
  description = "Create a Let's Encrypt production ClusterIssuer"
  type        = bool
  default     = false
}
