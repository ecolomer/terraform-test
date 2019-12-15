variable "project_name" {
  description = "Project name"
  type = string
}

variable "project_owner" {
  description = "Project owner"
  type = string
}

variable "environment" {
  description = "Project environment"
  type = string
  default = "dev"
}

variable "s3_bucket" {
  description = "S3 bucket storing Lambda deployment packages"
  type = string
}

variable "custom_tags" {
  description = "Custom tags applied to module resources"
  type = map(string)
  default = {}
}

