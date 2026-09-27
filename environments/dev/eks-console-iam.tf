# IAM API permissions for the EKS console (cluster list/describe). Kubernetes
# authorization for the Nodes view is granted via EKS access entries
# (AmazonEKSViewPolicy) in main.tf.
data "aws_iam_policy_document" "eks_console_viewer" {
  statement {
    sid    = "EKSConsoleReadOnly"
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:DescribeNodegroup",
      "eks:DescribeAccessEntry",
      "eks:DescribeAddon",
      "eks:DescribeFargateProfile",
      "eks:DescribeInsight",
      "eks:DescribeUpdate",
      "eks:ListAccessEntries",
      "eks:ListAccessPolicies",
      "eks:ListAddons",
      "eks:ListAssociatedAccessPolicies",
      "eks:ListClusters",
      "eks:ListFargateProfiles",
      "eks:ListInsights",
      "eks:ListNodegroups",
      "eks:ListUpdates",
      "eks:AccessKubernetesApi",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks_console_viewer" {
  name        = "${var.cluster_name}-console-viewer"
  description = "IAM permissions for read-only EKS console access to ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.eks_console_viewer.json

  tags = var.tags
}

locals {
  eks_console_viewer_iam_user_names = {
    for arn in local.eks_console_viewer_principal_arns :
    arn => element(split("/", arn), length(split("/", arn)) - 1)
    if can(regex(":user/", arn))
  }

  eks_console_viewer_iam_role_names = {
    for arn in local.eks_console_viewer_principal_arns :
    arn => element(split("/", arn), length(split("/", arn)) - 1)
    if can(regex(":role/", arn)) && !can(regex("aws-service-role/", arn))
  }
}

resource "aws_iam_user_policy_attachment" "eks_console_viewer" {
  for_each = local.eks_console_viewer_iam_user_names

  user       = each.value
  policy_arn = aws_iam_policy.eks_console_viewer.arn
}

resource "aws_iam_role_policy_attachment" "eks_console_viewer" {
  for_each = local.eks_console_viewer_iam_role_names

  role       = each.value
  policy_arn = aws_iam_policy.eks_console_viewer.arn
}
