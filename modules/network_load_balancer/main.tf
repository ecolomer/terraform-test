locals {
  module_tags = {
    terraform : "true",
    terraform_module : "network_load_balancer",
  }
}

resource "aws_lb" "main" {
  name               = var.lb_name
  internal           = var.lb_internal
  load_balancer_type = "network"
  subnets            = var.lb_subnets
  tags = merge(
    {
      Name = var.lb_name
    },
    local.module_tags,
    var.custom_tags
  )
}

# Create this resource as many times as ports defined as var 
resource "aws_lb_listener" "main_listener" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.lb_ports
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main_target_group.arn
  }
}

resource "aws_lb_target_group" "main_target_group" {
  name     = var.target_group_name
  port     = var.target_port
  protocol = "TCP"
  vpc_id   = var.vpc_id
  tags = merge(
    local.module_tags,
    var.custom_tags
  )
}
