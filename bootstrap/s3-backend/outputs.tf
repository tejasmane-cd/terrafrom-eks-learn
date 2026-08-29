output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "dev_backend_config" {
  value = "terraform -chdir=environments/dev init -backend-config=\"bucket=${aws_s3_bucket.terraform_state.bucket}\" -backend-config=\"region=${var.aws_region}\""
}

output "prod_backend_config" {
  value = "terraform -chdir=environments/prod init -backend-config=\"bucket=${aws_s3_bucket.terraform_state.bucket}\" -backend-config=\"region=${var.aws_region}\""
}
