output "instance_id" {
  value = aws_instance.this.id
}

output "instance_public_ip" {
  value = aws_instance.this.public_ip
}

output "security_group_id" {
  value = aws_security_group.this.id
}

output "elastic_ip" {
  value = var.elastic_ip ? aws_eip.this[0].public_ip : ""
}

output "iam_role_name" {
  value = aws_iam_role.instance.name
}