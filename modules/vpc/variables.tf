variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  validation {
    condition     = var.az_count >= 1 && var.az_count <= 6
    error_message = "az_count must be between 1 and 6. Ensure the target region has at least this many AZs."
  }
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway (cheaper for dev)"
  type        = bool
}

variable "tags" {
  description = "Additional tags applied to all resources"
  type        = map(string)
  default     = {}
}
