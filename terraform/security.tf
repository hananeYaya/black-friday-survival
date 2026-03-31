# Security Groups pour EKS
resource "aws_security_group" "eks_additional" {
  name_prefix = "${local.name}-additional-"
  vpc_id      = module.vpc.vpc_id
  description = "Additional security group for EKS cluster nodes"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-additional-sg"
    }
  )
}

# Security Group Rules pour restreindre l'accès
resource "aws_security_group_rule" "eks_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.eks_additional.id
  description       = "Allow HTTPS from trusted sources"
}

resource "aws_security_group_rule" "eks_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.eks_additional.id
  description       = "Allow HTTP from trusted sources"
}

# Security Group pour ALB
resource "aws_security_group" "alb" {
  name_prefix = "${local.name}-alb-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for Application Load Balancer"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from internet"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-alb-sg"
    }
  )
}

# WAF Web ACL pour protéger les endpoints
resource "aws_wafv2_web_acl" "main" {
  name  = "${local.name}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Règle : Rate limiting (max 2000 requêtes par IP en 5 minutes)
  rule {
    name     = "rate-limit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  # Règle : AWS Managed Rules - Core Rule Set
  rule {
    name     = "aws-managed-core-rules"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name}-core-rules"
      sampled_requests_enabled   = true
    }
  }

  # Règle : AWS Managed Rules - Known Bad Inputs
  rule {
    name     = "aws-managed-known-bad-inputs"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # Règle : AWS Managed Rules - SQL Injection
  rule {
    name     = "aws-managed-sqli"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name}-sqli"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name}-waf"
    sampled_requests_enabled   = true
  }

  tags = local.tags
}

# CloudWatch Log Group pour WAF
resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-eks-bfs-gp12"  # Format spécial pour WAF
  retention_in_days = 7

  tags = local.tags
}

# Note: WAF logging configuration nécessite un format ARN spécial
# Désactivé temporairement car nécessite configuration Kinesis Firehose
# resource "aws_wafv2_web_acl_logging_configuration" "main" {
#   resource_arn            = aws_wafv2_web_acl.main.arn
#   log_destination_configs = ["${aws_cloudwatch_log_group.waf.arn}"]
# }

# KMS Key pour chiffrement des secrets EKS
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key for ${local.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.tags
}

# Note: KMS Alias créé automatiquement par le module EKS
