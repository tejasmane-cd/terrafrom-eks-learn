variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name used for tagging"
  type        = string
}

variable "aws_region" {
  description = "AWS region (required for Route53 DNS-01 solver)"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "acme_email" {
  description = "Email address for the Let's Encrypt ACME account"
  type        = string
}

variable "chart_version" {
  description = "Pinned Helm chart version for cert-manager"
  type        = string
  default     = "v1.17.2"
}

variable "ingress_class" {
  description = "Ingress class used by the HTTP-01 solver (set to alb when using AWS Load Balancer Controller)"
  type        = string
  default     = "alb"
}

variable "acme_solver_type" {
  description = "ACME challenge solver: http01 (ALB Ingress) or dns01 (Route53)"
  type        = string
  default     = "http01"

  validation {
    condition     = contains(["http01", "dns01"], var.acme_solver_type)
    error_message = "acme_solver_type must be http01 or dns01."
  }
}

variable "route53_hosted_zone_arns" {
  description = "Route53 hosted zone ARNs for DNS-01 challenges (required when acme_solver_type is dns01)"
  type        = list(string)
  default     = []

  validation {
    condition     = var.acme_solver_type != "dns01" || length(var.route53_hosted_zone_arns) > 0
    error_message = "Set route53_hosted_zone_arns when acme_solver_type is dns01."
  }
}

variable "enable_staging_issuer" {
  description = "Create a Let's Encrypt staging ClusterIssuer"
  type        = bool
  default     = true
}

variable "enable_production_issuer" {
  description = "Create a Let's Encrypt production ClusterIssuer"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
