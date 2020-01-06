variable "aws_region" {
  description = "AWS region for Terratest tests"
  type = string
}

variable "instance_name" {
  description = "Instance name"
  type = string
}

variable "instance_type" {
  description = "Instance type"
  type = string
  default = "t2.micro"
}

variable "ami" {
  description = "Amazon Machine Image"
  type = string
}

variable "keypair" {
  description = "Key pair name"
  type = string
  default = null
}

variable "vpc" {
  description = "VPC identifier"
  type = string
  default = null
}

variable "subnet" {
  description = "Subnet identifier"
  type = string
  default = null
}

variable "volume_size" {
  description = "Disk space (in GB)"
  type = number
}

variable "elastic_ip" {
  description = "Assign Elastic IP to instance"
  type = bool
}

variable "inbound_security_rules" {
  description = "Inbound security group rules"
  type = set(object({ port = number, protocol = string, source = list(string), description = string }))
}

variable "outbound_security_rules" {
  description = "Outbound security group rules"
  type = set(object({ port = number, protocol = string, destination = list(string), description = string }))
}

variable "security_groups" {
  description = "Security groups to attach to instance"
  type = list(string)
  default = []
}

variable "custom_policies" {
  description = "Set of files with JSON AWS policies"
  type = set(string)
  default = []
}

variable "managed_policies" {
  description = "ARN of AWS/Customer Managed policies"
  type = set(string)
}

variable "custom_tags" {
  description = "Custom tags applied to module resources"
  type = map(string)
  default = {
    project = "stack-instance"
    env = "prod"
    owner = "infrastructure"
  }
}