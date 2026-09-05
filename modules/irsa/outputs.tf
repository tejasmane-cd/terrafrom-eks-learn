output "iam_role_arn" {
  description = "ARN of the IAM role for the Kubernetes service account"
  value       = module.irsa.arn
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = module.irsa.name
}
