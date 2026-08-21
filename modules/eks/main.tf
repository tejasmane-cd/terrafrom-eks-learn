locals {
  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.cluster_name
    },
    var.tags,
  )

  eks_managed_node_groups = {
    for name, cfg in var.eks_managed_node_groups : name => merge(
      {
        instance_types = cfg.instance_types
        capacity_type  = cfg.capacity_type
        min_size       = cfg.min_size
        max_size       = cfg.max_size
        desired_size   = cfg.desired_size
        disk_size      = cfg.disk_size
      },
      {
        labels = {
          environment = var.environment
          nodegroup   = name
        }
      },
    )
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version
  region             = var.aws_region

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  endpoint_public_access       = var.endpoint_public_access
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  endpoint_private_access      = true

  enable_cluster_creator_admin_permissions = true
  deletion_protection                      = var.deletion_protection

  addons = {
    # Must run before nodes; otherwise nodes stay NotReady (CNI not initialized)
    # and Terraform waits on the node group indefinitely.
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
    kube-proxy = {
      most_recent    = true
      before_compute = true
    }
    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true
    }
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        replicaCount = var.coredns_replica_count
      })
    }
  }

  eks_managed_node_groups = local.eks_managed_node_groups

  tags = local.common_tags
}
