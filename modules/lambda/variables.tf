variable "custom_tags" {
  description = "Custom tags for application"
  type = map(string)
  default = {}
}

variable "package_name" {
  description = "Name of the source code package"
  type = string
}

variable "s3_bucket" {
  description = "S3 bucket storing deployment packages"
  type = string
}

variable "s3_key_prefix" {
  description = "Object key prefix for deployment packages"
  type = string
  default = ""
}

variable "function_name" {
  description = "Lambda function name"
  type = string
}

variable "function_source" {
  description = "Lambda function source directory"
  type = string
}

variable "function_runtime" {
  description = "Lambda function runtime"
  type = string
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

variable "custom_policies" {
  description = "Set of files with JSON policies"
  type = set(string)
  default = []
}

variable "aws_managed_policies" {
  description = "ARNs of the Managed AWS policies"
  type = set(string)
  default = []
}
