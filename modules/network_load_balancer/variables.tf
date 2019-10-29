variable "lb_subnets" {
  description = "List of subnet IDs where the LB will be attached to."
  type        = list(string)
}

variable "lb_internal" {
  description = "Wether the LB should be internal or not. Default to false."
  type        = bool
  default     = false
}

variable "lb_name" {
  description = "Name of the LB."
  type        = string
}

variable "custom_tags" {
  description = "Tags that would be attached to every component of this module."
  type        = map(string)
  default     = {}
}

# TO be updated to a list
variable "lb_ports" {
  description = "List of ports where the load balancer will be listening to."
  type        = number
}

variable "target_group_name" {
  description = "Name of the target group."
  type        = string
}

variable "target_port" {
  description = "Port where the LB will send the network traffic to."
  type        = number
}

variable "vpc_id" {
  description = "VPC ID where the target group will be placed."
  type        = string
}




