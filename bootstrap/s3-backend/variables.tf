variable "aws_region" {
  description = "AWS region where the Terraform state bucket is created"
  type        = string
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state. Do not commit a real value."
  type        = string
}

variable "allowed_principal_arns" {
  description = "IAM role/user ARNs allowed to read/write Terraform state objects and lock files"
  type        = list(string)
  default     = []
}
