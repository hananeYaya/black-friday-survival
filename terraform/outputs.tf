# EKS Cluster Outputs
output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "aws_region" {
  description = "AWS Region"
  value       = var.aws_region
}

output "cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_arn" {
  description = "EKS Cluster ARN"
  value       = module.eks.cluster_arn
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_version" {
  description = "Kubernetes version"
  value       = module.eks.cluster_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

# OIDC Provider
output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = module.eks.oidc_provider_arn
}

# VPC Outputs (conditional)
output "vpc_id" {
  description = "VPC ID"
  value       = var.create_vpc ? module.vpc[0].vpc_id : var.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = var.create_vpc ? module.vpc[0].private_subnets : var.subnet_ids
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = var.create_vpc ? module.vpc[0].public_subnets : []
}

# IAM Role ARNs
output "ebs_csi_driver_role_arn" {
  description = "IAM Role ARN for EBS CSI Driver"
  value       = module.ebs_csi_irsa_role.iam_role_arn
}

output "cluster_autoscaler_role_arn" {
  description = "IAM Role ARN for Cluster Autoscaler"
  value       = module.cluster_autoscaler_irsa_role.iam_role_arn
}

output "load_balancer_controller_role_arn" {
  description = "IAM Role ARN for AWS Load Balancer Controller"
  value       = module.aws_load_balancer_controller_irsa_role.iam_role_arn
}

# CloudWatch Outputs
output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group for EKS Cluster"
  value       = aws_cloudwatch_log_group.eks_cluster.name
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch Dashboard Name"
  value       = aws_cloudwatch_dashboard.eks_monitoring.dashboard_name
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for alerts"
  value       = var.create_sns_topic ? aws_sns_topic.alerts[0].arn : var.sns_topic_arn
}

# kubectl config command
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
