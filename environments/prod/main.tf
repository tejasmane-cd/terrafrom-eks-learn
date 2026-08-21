moved {
  from = module.eks_platform.module.vpc
  to   = module.vpc.module.vpc
}

moved {
  from = module.eks_platform.module.eks
  to   = module.eks.module.eks
}

module "vpc" {
  source = "../../modules/vpc"

  environment  = var.environment
  cluster_name = var.cluster_name
  vpc_cidr     = var.vpc_cidr

  az_count           = 3
  single_nat_gateway = false

  tags = var.tags
}

module "eks" {
  source = "../../modules/eks"

  environment  = var.environment
  cluster_name = var.cluster_name
  aws_region   = var.aws_region

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  kubernetes_version = var.kubernetes_version

  # Private-only endpoint: kubectl and all subsequent Terraform runs must be
  # executed from within the VPC (VPN, bastion, or AWS CloudShell in the VPC).
  # Ensure your VPN/bastion is running BEFORE applying and add its SG to the
  # cluster security group if needed.
  endpoint_public_access       = false
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  deletion_protection          = true

  coredns_replica_count = 2

  eks_managed_node_groups = {
    default = {
      instance_types = ["m6i.large"]
      capacity_type  = "ON_DEMAND"
      min_size       = 2
      max_size       = 10
      desired_size   = 3
      disk_size      = 100
    }
  }

  tags = var.tags
}
