output "namespace" {
  description = "Namespace where cert-manager is installed"
  value       = kubernetes_namespace_v1.this.metadata[0].name
}

output "staging_cluster_issuer" {
  description = "Name of the Let's Encrypt staging ClusterIssuer"
  value       = var.enable_staging_issuer ? local.staging_issuer_name : null
}

output "production_cluster_issuer" {
  description = "Name of the Let's Encrypt production ClusterIssuer"
  value       = var.enable_production_issuer ? local.production_issuer_name : null
}

output "iam_role_arn" {
  description = "IRSA role ARN when using Route53 DNS-01 (null for HTTP-01)"
  value       = local.use_route53_irsa ? module.irsa[0].iam_role_arn : null
}
