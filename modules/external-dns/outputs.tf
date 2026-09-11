output "namespace" {
  description = "Namespace where External DNS is installed"
  value       = kubernetes_namespace_v1.this.metadata[0].name
}

output "iam_role_arn" {
  description = "IRSA role ARN used by External DNS"
  value       = module.irsa.iam_role_arn
}

output "txt_owner_id" {
  description = "TXT record owner ID used to identify records managed by this cluster"
  value       = local.txt_owner_id
}

output "domain_filters" {
  description = "Domains External DNS is configured to manage"
  value       = var.domain_filters
}
