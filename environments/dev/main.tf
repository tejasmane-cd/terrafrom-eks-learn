module "eks_platform" {
  source = "../../modules/eks-platform"

  environment  = var.environment
  cluster_name = var.cluster_name
  aws_region   = var.aws_region
  vpc_cidr     = var.vpc_cidr

  az_count           = 2
  single_nat_gateway = true

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
