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
  source = "../irsa"

  environment  = var.environment
  cluster_name = var.cluster_name
  name         = "${var.cluster_name}-ebs-csi"

  oidc_provider_arn          = var.oidc_provider_arn
  namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]

  attach_ebs_csi_policy = true
  ebs_csi_kms_cmk_arns  = var.kms_cmk_arns

  tags = var.tags
}

resource "aws_eks_addon" "this" {
  cluster_name = var.cluster_name
  addon_name   = "aws-ebs-csi-driver"

  addon_version               = var.addon_version
  service_account_role_arn    = module.irsa.iam_role_arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = local.common_tags
}

resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type = "gp3"
  }

  depends_on = [aws_eks_addon.this]
}
