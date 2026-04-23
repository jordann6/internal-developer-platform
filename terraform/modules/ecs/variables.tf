variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "idp"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ecr_repository_url" {
  description = "ECR repository URL for the Backstage image"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ECR repository ARN for IAM permissions"
  type        = string
}

variable "db_credentials_secret_arn" {
  description = "Secrets Manager ARN for database credentials"
  type        = string
}

variable "db_hostname" {
  description = "RDS hostname"
  type        = string
}

variable "db_port" {
  description = "RDS port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "backstage"
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting logs"
  type        = string
}

variable "alb_security_group_id" {
  description = "ALB security group ID for ingress rules"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name for Backstage base URL"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

variable "task_cpu" {
  description = "Fargate task CPU units"
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "Fargate task memory in MB"
  type        = string
  default     = "1024"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
