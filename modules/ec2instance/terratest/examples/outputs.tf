output "instance_id" {
  value = module.instance.instance_id
}

output "instance_public_ip" {
  value = module.instance.instance_public_ip
}

output "elastic_ip" {
  value = module.instance.elastic_ip
}

output "iam_role_name" {
  value = module.instance.iam_role_name
}