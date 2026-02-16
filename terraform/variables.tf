variable "aws_region" {
  description = "Region AWS"
  type        = string
  default     = "eu-west-3"
}

variable "aws_profile" {
  description = "AWS CLI profile (optional)"
  type        = string
  default     = "default"
}

variable "cluster_name" {
  description = "Nom du cluster EKS"
  type        = string
  default     = "black-friday-eks"
}

variable "vpc_id" {
  description = "VPC id to deploy EKS into"
  type        = string
  default     = "vpc-07e730880601eb848"
}

variable "subnet_ids" {
  description = "List of subnet ids for EKS nodes"
  type        = list(string)
  default = [
    "subnet-0c8e26fa3ca9a2271",
    "subnet-02686c08f6c0c54a9",
  ]
}
