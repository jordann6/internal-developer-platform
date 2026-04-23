variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "idp"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "backstage"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "backstage"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
