variable "default_tags" {
  description = "Default tags applied to module resources"
  type        = map(string)
  default     = {
    "env" = "dev",
    "project" = "common",
    "built-using" = "terraform"
    "terraform-module" = "lambda"
  }
}

variable "custom_tags" {
  description = "Custom tags applied to module resources"
  type = map(string)
  default = {}
}

variable "s3_bucket" {
  description = "S3 bucket storing deployment packages"
  type = string
}

variable "function_name" {
  description = "Lambda function name"
  type = string
}

variable "function_source" {
  description = "Lambda function local source directory"
  type = string
  default = "source"
}

variable "function_runtime" {
  description = "Lambda function runtime"
  type = string
  default = "python3.6"
}

variable "function_memory" {
  description = "Lambda function memory size (in MB)"
  type = number
  default = null
}

variable "function_timeout" {
  description = "Lambda function timeout (in seconds)"
  type = number
  default = null
}

variable "handler_config" {
  description = "Lambda function handler configuration"
  type = object({ module=string, function=string })
}

variable "vpc_config" {
  description = "Lambda function VPC configuration"
  type = object({ vpc_id=string, subnets=set(string) })
  default = { vpc_id=null, subnets=[] }
}

variable "env_vars" {
  description = "Lambda function environment variables"
  type = map(string)
  default = null
}

variable "custom_policies" {
  description = "Set of files with JSON AWS policies"
  type = set(string)
  default = []
}

variable "aws_managed_policies" {
  description = "Name of AWS Managed policies"
  type = set(string)
  default = []
}