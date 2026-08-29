resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "retain-noncurrent-state-versions"
    status = "Enabled"

    filter {
      prefix = "terrafrom-eks-learn/"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "terraform_state" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.terraform_state.arn,
      "${aws_s3_bucket.terraform_state.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  dynamic "statement" {
    for_each = length(var.allowed_principal_arns) > 0 ? [1] : []

    content {
      sid    = "AllowTerraformStateAccess"
      effect = "Allow"

      actions = [
        "s3:ListBucket",
      ]

      resources = [aws_s3_bucket.terraform_state.arn]

      principals {
        type        = "AWS"
        identifiers = var.allowed_principal_arns
      }

      condition {
        test     = "StringLike"
        variable = "s3:prefix"
        values   = ["terrafrom-eks-learn/*"]
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.allowed_principal_arns) > 0 ? [1] : []

    content {
      sid    = "AllowTerraformStateObjects"
      effect = "Allow"

      actions = [
        "s3:GetObject",
        "s3:PutObject",
      ]

      resources = [
        "${aws_s3_bucket.terraform_state.arn}/terrafrom-eks-learn/dev/terraform.tfstate",
        "${aws_s3_bucket.terraform_state.arn}/terrafrom-eks-learn/prod/terraform.tfstate",
      ]

      principals {
        type        = "AWS"
        identifiers = var.allowed_principal_arns
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.allowed_principal_arns) > 0 ? [1] : []

    content {
      sid    = "AllowTerraformLockFiles"
      effect = "Allow"

      actions = [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:PutObject",
      ]

      resources = [
        "${aws_s3_bucket.terraform_state.arn}/terrafrom-eks-learn/dev/terraform.tfstate.tflock",
        "${aws_s3_bucket.terraform_state.arn}/terrafrom-eks-learn/prod/terraform.tfstate.tflock",
      ]

      principals {
        type        = "AWS"
        identifiers = var.allowed_principal_arns
      }
    }
  }
}

resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  policy = data.aws_iam_policy_document.terraform_state.json
}
