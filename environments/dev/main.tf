moved {
  from = module.eks_platform.module.vpc
  to   = module.vpc.module.vpc
}

moved {
  from = module.eks_platform.module.eks
  to   = module.eks.module.eks
}

data "aws_iam_role" "github_actions_terraform_dev" {
  name = "github-actions-terraform-dev"
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

  enable_cluster_creator_admin_permissions = false
  access_entries = {
    cluster_creator = {
      principal_arn = data.aws_iam_role.github_actions_terraform_dev.arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.small"]
      capacity_type  = "ON_DEMAND"
      min_size       = 1
      max_size       = 2
      desired_size   = 2
      disk_size      = 20
    }
  }

  tags = var.tags
}

module "ebs_csi" {
  source = "../../modules/ebs-csi"

  providers = {
    kubernetes = kubernetes
  }

  environment       = var.environment
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  addon_version     = var.ebs_csi_addon_version
  tags              = var.tags

  depends_on = [module.eks]
}

module "aws_load_balancer_controller" {
  source = "../../modules/aws-load-balancer-controller"

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  environment            = var.environment
  cluster_name           = module.eks.cluster_name
  aws_region             = var.aws_region
  vpc_id                 = module.vpc.vpc_id
  oidc_provider_arn      = module.eks.oidc_provider_arn
  chart_version          = var.aws_load_balancer_controller_chart_version
  create_example_ingress = var.create_example_ingress
  example_ingress_scheme = var.example_ingress_scheme
  tags                   = var.tags

  depends_on = [module.eks]
}
