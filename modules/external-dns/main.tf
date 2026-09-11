locals {
  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.cluster_name
    },
    var.tags,
  )

  namespace            = "external-dns"
  service_account_name = "external-dns"
  txt_owner_id         = coalesce(var.txt_owner_id, var.cluster_name)
}

module "irsa" {
  source = "../irsa"

  environment  = var.environment
  cluster_name = var.cluster_name
  name         = "${var.cluster_name}-external-dns"

  oidc_provider_arn          = var.oidc_provider_arn
  namespace_service_accounts = ["${local.namespace}:${local.service_account_name}"]

  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = var.route53_hosted_zone_arns

  tags = var.tags
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = local.namespace
    labels = {
      "app.kubernetes.io/name" = "external-dns"
    }
  }
}

resource "kubernetes_service_account_v1" "external_dns" {
  metadata {
    name      = local.service_account_name
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.irsa.iam_role_arn
    }
  }
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.this.metadata[0].name

  values = [
    yamlencode({
      provider = {
        name = "aws"
      }

      serviceAccount = {
        create = false
        name   = local.service_account_name
      }

      env = [
        {
          name  = "AWS_DEFAULT_REGION"
          value = var.aws_region
        },
      ]

      policy        = var.policy
      txtOwnerId    = local.txt_owner_id
      domainFilters = var.domain_filters
      sources       = var.sources
    }),
  ]

  depends_on = [kubernetes_service_account_v1.external_dns]
}
