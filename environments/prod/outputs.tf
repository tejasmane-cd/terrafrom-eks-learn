output "vpc_id" {
  value = module.vpc.vpc_id
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  value = module.eks.configure_kubectl
}

output "ebs_csi_storage_class" {
  description = "gp3 StorageClass backed by the EBS CSI driver"
  value       = module.ebs_csi.storage_class_name
}

output "alb_ingress_class" {
  description = "IngressClass for ALB-backed Ingress resources"
  value       = module.aws_load_balancer_controller.ingress_class_name
}

output "cert_manager_production_issuer" {
  description = "Let's Encrypt production ClusterIssuer for automatic TLS"
  value       = module.cert_manager.production_cluster_issuer
}

output "external_dns_txt_owner_id" {
  description = "TXT owner ID when External DNS is enabled"
  value       = var.enable_external_dns ? module.external_dns[0].txt_owner_id : null
}
