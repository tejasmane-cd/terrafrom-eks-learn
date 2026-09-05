variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name used for tagging"
  type        = string
}

variable "name" {
  description = "IAM role name suffix (e.g. ebs-csi, aws-lb-controller)"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "namespace_service_accounts" {
  description = "Kubernetes namespace:serviceaccount pairs allowed to assume this role"
  type        = list(string)
}

variable "attach_ebs_csi_policy" {
  description = "Attach the AWS EBS CSI driver IAM policy"
  type        = bool
  default     = false
}

variable "attach_load_balancer_controller_policy" {
  description = "Attach the AWS Load Balancer Controller IAM policy"
  type        = bool
  default     = false
}

variable "attach_load_balancer_controller_aga_policy" {
  description = "Attach the AWS Load Balancer Controller Global Accelerator IAM policy"
  type        = bool
  default     = false
}

variable "attach_cluster_autoscaler_policy" {
  description = "Attach the cluster autoscaler IAM policy"
  type        = bool
  default     = false
}

variable "attach_external_dns_policy" {
  description = "Attach the External DNS IAM policy"
  type        = bool
  default     = false
}

variable "attach_cert_manager_policy" {
  description = "Attach the cert-manager IAM policy"
  type        = bool
  default     = false
}

variable "attach_external_secrets_policy" {
  description = "Attach the External Secrets IAM policy"
  type        = bool
  default     = false
}

variable "attach_vpc_cni_policy" {
  description = "Attach the VPC CNI IAM policy"
  type        = bool
  default     = false
}

variable "attach_cloudwatch_observability_policy" {
  description = "Attach the CloudWatch observability IAM policy"
  type        = bool
  default     = false
}

variable "attach_amazon_managed_service_prometheus_policy" {
  description = "Attach the Amazon Managed Prometheus IAM policy"
  type        = bool
  default     = false
}

variable "cluster_autoscaler_cluster_names" {
  description = "Cluster names scoped in the cluster autoscaler policy"
  type        = list(string)
  default     = []
}

variable "ebs_csi_kms_cmk_arns" {
  description = "KMS CMK ARNs the EBS CSI driver may use"
  type        = list(string)
  default     = []
}

variable "external_dns_hosted_zone_arns" {
  description = "Route53 hosted zone ARNs for External DNS"
  type        = list(string)
  default     = []
}

variable "cert_manager_hosted_zone_arns" {
  description = "Route53 hosted zone ARNs for cert-manager"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags applied to the IAM role"
  type        = map(string)
  default     = {}
}
