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

  az_count           = 2
  single_nat_gateway = true

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

  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  deletion_protection          = false

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.small"]
      capacity_type  = "ON_DEMAND"
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      disk_size      = 20
    }
  }

  tags = var.tags
}
