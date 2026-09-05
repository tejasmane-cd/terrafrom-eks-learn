output "iam_role_arn" {
  description = "IRSA role ARN used by the AWS Load Balancer Controller"
  value       = module.irsa.iam_role_arn
}

output "ingress_class_name" {
  description = "IngressClass name for ALB-backed Ingress resources"
  value       = kubernetes_ingress_class_v1.alb.metadata[0].name
}

output "example_ingress_name" {
  description = "Name of the demo Ingress when create_example_ingress is true"
  value       = var.create_example_ingress ? kubernetes_ingress_v1.demo[0].metadata[0].name : null
}

output "example_namespace" {
  description = "Namespace of the demo Ingress when create_example_ingress is true"
  value       = var.create_example_ingress ? kubernetes_namespace_v1.demo[0].metadata[0].name : null
}
