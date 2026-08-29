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
  description = "VPC ID where the EKS cluster is deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS nodes"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
}

variable "addon_versions" {
  description = "Pinned Amazon EKS add-on versions compatible with the selected Kubernetes version"
  type        = map(string)
  default = {
    coredns                = "v1.14.3-eksbuild.14"
    kube-proxy             = "v1.36.0-eksbuild.17"
    vpc-cni                = "v1.22.4-eksbuild.3"
    eks-pod-identity-agent = "v1.3.10-eksbuild.2"
  }
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
}

variable "endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public API endpoint"
  type        = list(string)
}

variable "deletion_protection" {
  description = "Enable EKS cluster deletion protection"
  type        = bool
}

variable "eks_managed_node_groups" {
  description = "EKS managed node group configuration"
  type = map(object({
    instance_types = list(string)
    capacity_type  = optional(string, "ON_DEMAND")
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = optional(number, 50)
  }))
}

variable "coredns_replica_count" {
  description = "CoreDNS replica count (use 1 for dev to fit small nodes; use >=2 in prod for HA)"
  type        = number
  default     = 1
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Indicates whether to create the EKS bootstrap cluster creator admin access entry from the Terraform caller identity"
  type        = bool
  default     = false
}

variable "access_entries" {
  description = "Map of explicit EKS access entries to add to the cluster"
  type = map(object({
    kubernetes_groups = optional(list(string))
    principal_arn     = string
    type              = optional(string, "STANDARD")
    user_name         = optional(string)
    tags              = optional(map(string), {})
    policy_associations = optional(map(object({
      policy_arn = string
      access_scope = object({
        namespaces = optional(list(string))
        type       = string
      })
    })), {})
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags applied to all resources"
  type        = map(string)
  default     = {}
}
