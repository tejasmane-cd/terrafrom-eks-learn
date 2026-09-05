output "iam_role_arn" {
  description = "IRSA role ARN used by the EBS CSI controller"
  value       = module.irsa.iam_role_arn
}

output "storage_class_name" {
  description = "Name of the gp3 StorageClass created by this module"
  value       = kubernetes_storage_class_v1.gp3.metadata[0].name
}
