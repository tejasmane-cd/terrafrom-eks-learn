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
  default     = "dns01"
}

variable "cert_manager_route53_hosted_zone_arns" {
  description = "Route53 zone ARNs for DNS-01 (required when cert_manager_acme_solver_type is dns01)"
  type        = list(string)
  default     = []
}

variable "cert_manager_enable_staging_issuer" {
  description = "Create a Let's Encrypt staging ClusterIssuer"
  type        = bool
  default     = false
}

variable "cert_manager_enable_production_issuer" {
  description = "Create a Let's Encrypt production ClusterIssuer"
  type        = bool
  default     = true
}

variable "enable_external_dns" {
  description = "Deploy External DNS for automated Route53 record management"
  type        = bool
  default     = false
}

variable "external_dns_route53_hosted_zone_arns" {
  description = "Route53 hosted zone ARNs External DNS may manage"
  type        = list(string)
  default     = []
}

variable "external_dns_domain_filters" {
  description = "Domains External DNS is allowed to manage (e.g. example.com)"
  type        = list(string)
  default     = []
}

variable "external_dns_chart_version" {
  description = "Pinned Helm chart version for External DNS"
  type        = string
  default     = "1.15.2"
}

variable "external_dns_policy" {
  description = "DNS record policy: sync, upsert-only, or create-only"
  type        = string
  default     = "upsert-only"
}

variable "external_dns_txt_owner_id" {
  description = "TXT owner ID for External DNS (defaults to cluster name)"
  type        = string
  default     = null
}
