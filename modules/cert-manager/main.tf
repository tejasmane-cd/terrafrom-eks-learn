locals {
  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.cluster_name
    },
    var.tags,
  )

  namespace            = "cert-manager"
  service_account_name = "cert-manager"
  use_route53_irsa     = var.acme_solver_type == "dns01"

  staging_issuer_name    = "letsencrypt-staging"
  production_issuer_name = "letsencrypt-production"

  acme_solvers = var.acme_solver_type == "dns01" ? [
    {
      dns01 = {
        route53 = {
          region = var.aws_region
        }
      }
    },
    ] : [
    {
      http01 = {
        ingress = {
          class = var.ingress_class
        }
      }
    },
  ]
}

module "irsa" {
  count = local.use_route53_irsa ? 1 : 0

  source = "../irsa"

  environment  = var.environment
  cluster_name = var.cluster_name
  name         = "${var.cluster_name}-cert-manager"

  oidc_provider_arn          = var.oidc_provider_arn
  namespace_service_accounts = ["${local.namespace}:${local.service_account_name}"]

  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = var.route53_hosted_zone_arns

  tags = var.tags
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = local.namespace
    labels = {
      "app.kubernetes.io/name" = "cert-manager"
    }
  }
}

resource "kubernetes_service_account_v1" "cert_manager" {
  count = local.use_route53_irsa ? 1 : 0

  metadata {
    name      = local.service_account_name
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.irsa[0].iam_role_arn
    }
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.this.metadata[0].name

  values = [
    yamlencode({
      installCRDs = true

      serviceAccount = local.use_route53_irsa ? {
        create = false
        name   = local.service_account_name
        } : {
        create = true
        name   = local.service_account_name
      }
    }),
  ]

  depends_on = [kubernetes_service_account_v1.cert_manager]
}

resource "kubernetes_manifest" "cluster_issuer_staging" {
  count = var.enable_staging_issuer ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = local.staging_issuer_name
    }
    spec = {
      acme = {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email  = var.acme_email
        privateKeySecretRef = {
          name = "${local.staging_issuer_name}-account-key"
        }
        solvers = local.acme_solvers
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_manifest" "cluster_issuer_production" {
  count = var.enable_production_issuer ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = local.production_issuer_name
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.acme_email
        privateKeySecretRef = {
          name = "${local.production_issuer_name}-account-key"
        }
        solvers = local.acme_solvers
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}
