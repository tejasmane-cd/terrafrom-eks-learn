output "vpc_id" {
  value = module.eks_platform.vpc_id
}

output "cluster_name" {
  value = module.eks_platform.cluster_name
}

output "cluster_endpoint" {
  value = module.eks_platform.cluster_endpoint
}

output "configure_kubectl" {
  value = module.eks_platform.configure_kubectl
}
