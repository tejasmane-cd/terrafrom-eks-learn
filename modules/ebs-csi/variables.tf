variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "addon_version" {
  description = "Pinned aws-ebs-csi-driver EKS add-on version"
  type        = string
  default     = "v1.65.0-eksbuild.1"
}

variable "kms_cmk_arns" {
  description = "Optional KMS CMK ARNs for encrypted EBS volumes"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
