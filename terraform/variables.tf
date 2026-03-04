# AWS Configuration
variable "aws_region" {
  description = "Region AWS"
  type        = string
  default     = "eu-south-2"
}

variable "aws_profile" {
  description = "AWS CLI profile (optional)"
  type        = string
  default     = "default"
}

# Environment
variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# EKS Cluster Configuration
variable "cluster_name" {
  description = "Nom du cluster EKS"
  type        = string
  default     = "eks-bfs-gp12"
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "bfs-gp12"
}

variable "kubernetes_version" {
  description = "Version de Kubernetes"
  type        = string
  default     = "1.29"
}

# VPC Configuration
variable "create_vpc" {
  description = "Create a new VPC or use existing one"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC id to deploy EKS into (if create_vpc is false)"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "List of subnet ids for EKS nodes (if create_vpc is false)"
  type        = list(string)
  default     = []
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-south-2a", "eu-south-2b", "eu-south-2c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

# CloudWatch Configuration
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "create_sns_topic" {
  description = "Create SNS topic for alerts"
  type        = bool
  default     = true
}

variable "sns_topic_arn" {
  description = "SNS Topic ARN for CloudWatch alarms (if create_sns_topic is false)"
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
  default     = ""
}


