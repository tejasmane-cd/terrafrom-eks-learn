data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

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

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i + length(local.azs))]

  enable_nat_gateway   = true
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.common_tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name                = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  region              = var.aws_region

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

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
