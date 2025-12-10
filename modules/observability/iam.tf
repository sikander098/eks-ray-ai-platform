
# Data source for current AWS configuration
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get OIDC provider info from EKS cluster (passed via variable or data source)
# For simplicity, we'll assume the OIDC provider URL is passed or derived
# But better to use the IRSA module which handles the trust policy

# IAM Role for Loki
module "loki_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name = "${var.cluster_name}-loki-sa"

  role_policy_arns = {
    policy = aws_iam_policy.loki_s3.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["monitoring:loki"]
    }
  }

  tags = var.tags
}

# IAM Policy for Loki S3 Access
resource "aws_iam_policy" "loki_s3" {
  name        = "${var.cluster_name}-loki-s3-policy"
  description = "IAM policy for Loki to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.loki_logs.arn,
          "${aws_s3_bucket.loki_logs.arn}/*"
        ]
      }
    ]
  })
}

# IAM Role for Tempo
module "tempo_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name = "${var.cluster_name}-tempo-sa"

  role_policy_arns = {
    policy = aws_iam_policy.tempo_s3.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["monitoring:tempo"]
    }
  }

  tags = var.tags
}

# IAM Policy for Tempo S3 Access
resource "aws_iam_policy" "tempo_s3" {
  name        = "${var.cluster_name}-tempo-s3-policy"
  description = "IAM policy for Tempo to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.tempo_traces.arn,
          "${aws_s3_bucket.tempo_traces.arn}/*"
        ]
      }
    ]
  })
}
