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
