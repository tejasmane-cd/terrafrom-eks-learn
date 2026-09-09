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
      instance_types = ["t3.small"]
      capacity_type  = "ON_DEMAND"
      min_size       = 2
      max_size       = 10
      desired_size   = 3
      disk_size      = 100
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

module "cert_manager" {
  source = "../../modules/cert-manager"

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  environment       = var.environment
  cluster_name      = module.eks.cluster_name
  aws_region        = var.aws_region
  oidc_provider_arn = module.eks.oidc_provider_arn

  acme_email               = var.cert_manager_acme_email
  chart_version            = var.cert_manager_chart_version
  acme_solver_type         = var.cert_manager_acme_solver_type
  route53_hosted_zone_arns = var.cert_manager_route53_hosted_zone_arns
  enable_staging_issuer    = var.cert_manager_enable_staging_issuer
  enable_production_issuer = var.cert_manager_enable_production_issuer
  ingress_class            = module.aws_load_balancer_controller.ingress_class_name
  tags                     = var.tags

  depends_on = [module.aws_load_balancer_controller]
}
