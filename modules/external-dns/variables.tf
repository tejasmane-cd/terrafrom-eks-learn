variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name used for tagging and default txtOwnerId"
  type        = string
}

variable "aws_region" {
  description = "AWS region where Route53 hosted zones are managed"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "route53_hosted_zone_arns" {
  description = "Route53 hosted zone ARNs External DNS may manage"
  type        = list(string)

  validation {
    condition     = length(var.route53_hosted_zone_arns) > 0
    error_message = "At least one Route53 hosted zone ARN is required."
  }
}

variable "domain_filters" {
  description = "Domain names External DNS is allowed to manage (e.g. example.com)"
  type        = list(string)

  validation {
    condition     = length(var.domain_filters) > 0
    error_message = "At least one domain filter is required."
  }
}

variable "chart_version" {
  description = "Pinned Helm chart version for external-dns"
  type        = string
  default     = "1.15.2"
}

variable "policy" {
  description = "DNS record sync policy: sync, upsert-only, or create-only"
  type        = string
  default     = "upsert-only"

  validation {
    condition     = contains(["sync", "upsert-only", "create-only"], var.policy)
    error_message = "policy must be sync, upsert-only, or create-only."
  }
}

variable "txt_owner_id" {
  description = "Unique TXT record owner ID to avoid conflicts across clusters"
  type        = string
  default     = null
}

variable "sources" {
  description = "Kubernetes resources External DNS watches for DNS records"
  type        = list(string)
  default     = ["service", "ingress"]
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
