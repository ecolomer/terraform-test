output "instance_public_ip" {
  value = aws_instance.this.public_ip
}

output "elastic_ip" {
  value = var.elastic_ip ? aws_eip.this[0].public_ip : ""
}
