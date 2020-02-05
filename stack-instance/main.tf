locals {
  tags = {
    project = "stack-instance"
    env = "prod"
    owner = "infrastructure"
  }
}

module "instance" {
  source                 = "github.com/ecolomer/terraform-test//modules/ec2instance?ref=ec2-instance"

  instance_name = "test-instance"
  instance_type = "t2.micro"
  keypair = "ecolomer"
  ami = "ami-02df9ea15c1778c9c"
  subnet = "subnet-c4ba47a3"
  vpc = "vpc-2800f04f"

  inbound_security_rules = [
    { port = 80, protocol = "tcp", source = ["0.0.0.0/0"], description = "Allow all HTTP traffic" },
    { port = 443, protocol = "tcp", source = ["0.0.0.0/0"], description = "Allow all HTTPS traffic" }
  ]

  managed_policies = [
    "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  ]
}
