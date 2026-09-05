locals {
  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.cluster_name
    },
    var.tags,
  )
}

module "irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.2"

  name = var.name

  attach_ebs_csi_policy                           = var.attach_ebs_csi_policy
  attach_load_balancer_controller_policy          = var.attach_load_balancer_controller_policy
  attach_load_balancer_controller_aga_policy      = var.attach_load_balancer_controller_aga_policy
  attach_cluster_autoscaler_policy                = var.attach_cluster_autoscaler_policy
  attach_external_dns_policy                      = var.attach_external_dns_policy
  attach_cert_manager_policy                      = var.attach_cert_manager_policy
  attach_external_secrets_policy                  = var.attach_external_secrets_policy
  attach_vpc_cni_policy                           = var.attach_vpc_cni_policy
  attach_cloudwatch_observability_policy          = var.attach_cloudwatch_observability_policy
  attach_amazon_managed_service_prometheus_policy = var.attach_amazon_managed_service_prometheus_policy

  cluster_autoscaler_cluster_names = var.cluster_autoscaler_cluster_names
  ebs_csi_kms_cmk_arns             = var.ebs_csi_kms_cmk_arns
  external_dns_hosted_zone_arns    = var.external_dns_hosted_zone_arns
  cert_manager_hosted_zone_arns    = var.cert_manager_hosted_zone_arns

  oidc_providers = {
    this = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = var.namespace_service_accounts
    }
  }

  tags = local.common_tags
}
