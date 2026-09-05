locals {
  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.cluster_name
    },
    var.tags,
  )

  service_account_name = "aws-load-balancer-controller"
}

module "irsa" {
  source = "../irsa"

  environment  = var.environment
  cluster_name = var.cluster_name
  name         = "${var.cluster_name}-aws-lb-controller"

  oidc_provider_arn          = var.oidc_provider_arn
  namespace_service_accounts = ["kube-system:${local.service_account_name}"]

  attach_load_balancer_controller_policy = true

  tags = var.tags
}

resource "kubernetes_service_account_v1" "controller" {
  metadata {
    name      = local.service_account_name
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.irsa.iam_role_arn
    }
  }
}

resource "helm_release" "controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.chart_version
  namespace  = "kube-system"

  values = [
    yamlencode({
      clusterName = var.cluster_name
      region      = var.aws_region
      vpcId       = var.vpc_id

      serviceAccount = {
        create = false
        name   = local.service_account_name
      }
    }),
  ]

  depends_on = [kubernetes_service_account_v1.controller]
}

resource "kubernetes_ingress_class_v1" "alb" {
  metadata {
    name = "alb"
    annotations = {
      "ingressclass.kubernetes.io/is-default-class" = tostring(var.ingress_class_is_default)
    }
  }

  spec {
    controller = "ingress.k8s.aws/alb"
  }

  depends_on = [helm_release.controller]
}

resource "kubernetes_namespace_v1" "demo" {
  count = var.create_example_ingress ? 1 : 0

  metadata {
    name = var.example_namespace
    labels = {
      "app.kubernetes.io/name" = "alb-demo"
    }
  }
}

resource "kubernetes_deployment_v1" "demo" {
  count = var.create_example_ingress ? 1 : 0

  metadata {
    name      = "alb-demo"
    namespace = kubernetes_namespace_v1.demo[0].metadata[0].name
    labels = {
      app = "alb-demo"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "alb-demo"
      }
    }

    template {
      metadata {
        labels = {
          app = "alb-demo"
        }
      }

      spec {
        container {
          name  = "http-echo"
          image = "hashicorp/http-echo:1.0"

          args = ["-text=Hello from ALB via Ingress"]

          port {
            container_port = 5678
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "demo" {
  count = var.create_example_ingress ? 1 : 0

  metadata {
    name      = "alb-demo"
    namespace = kubernetes_namespace_v1.demo[0].metadata[0].name
  }

  spec {
    selector = {
      app = "alb-demo"
    }

    port {
      port        = 80
      target_port = "5678"
    }
  }

  depends_on = [kubernetes_deployment_v1.demo]
}

resource "kubernetes_ingress_v1" "demo" {
  count = var.create_example_ingress ? 1 : 0

  metadata {
    name      = "alb-demo"
    namespace = kubernetes_namespace_v1.demo[0].metadata[0].name
    annotations = {
      "alb.ingress.kubernetes.io/scheme"           = var.example_ingress_scheme
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/"
    }
  }

  spec {
    ingress_class_name = kubernetes_ingress_class_v1.alb.metadata[0].name

    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.demo[0].metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service_v1.demo,
    helm_release.controller,
  ]
}
