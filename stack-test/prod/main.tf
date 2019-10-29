# Network load balancer using Load Balancer module
module "network_load_balancer" {
  source = "../../modules/network_load_balancer"

  target_group_name = "LB-tg"
  lb_ports          = 80
  target_port       = 80
  vpc_id            = var.vpc_id
  lb_subnets        = var.public_subnet_ids
  lb_name           = "LoadBalancer"
}

