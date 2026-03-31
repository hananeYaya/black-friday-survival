# IAM Policy pour Pod Security
data "aws_iam_policy_document" "pod_security_policy" {
  statement {
    sid    = "DenyPrivilegedContainers"
    effect = "Deny"
    actions = [
      "eks:DescribeCluster"
    ]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# IAM Role pour les pods Online Boutique
module "online_boutique_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${local.name}-online-boutique"

  role_policy_arns = {
    CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["online-boutique:*"]
    }
  }

  tags = local.tags
}

# IAM Policy personnalisée pour limiter les actions
resource "aws_iam_policy" "restricted_pod_policy" {
  name        = "${local.name}-restricted-pod-policy"
  description = "Restricted policy for Online Boutique pods"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.tags
}

# Créer le namespace online-boutique
resource "kubernetes_namespace" "online_boutique" {
  metadata {
    name = "online-boutique"
    labels = {
      name    = "online-boutique"
      project = "bfs-gp12"
    }
  }

  depends_on = [module.eks]
}

# Pod Security Standards via EKS
resource "kubernetes_labels" "pod_security_standards" {
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = "online-boutique"
  }

  labels = {
    "pod-security.kubernetes.io/enforce" = "restricted"
    "pod-security.kubernetes.io/audit"   = "restricted"
    "pod-security.kubernetes.io/warn"    = "restricted"
  }

  depends_on = [kubernetes_namespace.online_boutique]
}

# Service Account pour Online Boutique avec IRSA
resource "kubernetes_service_account" "online_boutique" {
  metadata {
    name      = "online-boutique"
    namespace = "online-boutique"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.online_boutique_irsa_role.iam_role_arn
    }
  }

  depends_on = [kubernetes_namespace.online_boutique]
}

# Secrets encryption pour le namespace
resource "kubernetes_secret" "online_boutique_secrets" {
  metadata {
    name      = "online-boutique-secrets"
    namespace = "online-boutique"
  }

  type = "Opaque"

  data = {
    "tls.enabled" = "true"
  }

  depends_on = [kubernetes_namespace.online_boutique]
}

