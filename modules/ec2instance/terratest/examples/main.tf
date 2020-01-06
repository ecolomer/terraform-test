
module "instance" {
  source = "../.."

  instance_name = var.instance_name
  instance_type = var.instance_type
  keypair = var.keypair
  ami = var.ami
  subnet = var.subnet
  vpc = var.vpc
  elastic_ip = var.elastic_ip

  inbound_security_rules = var.inbound_security_rules
  outbound_security_rules = var.outbound_security_rules
  security_groups = var.security_groups

  managed_policies = var.managed_policies
  custom_tags = var.custom_tags
}
