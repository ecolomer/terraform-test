locals {
  # Set default tags
  tags = {
    project = var.instance_name
    env = "dev"
    owner = var.instance_name
    built-using = "terraform"
  }

  # Set default managed policies
  managed_policies = setunion(var.managed_policies, ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"])
}

# Used to generate "unique" names
resource "random_id" "id" {
  byte_length = 4
}

resource "aws_eip" "this" {
  count = var.elastic_ip ? 1 : 0
  instance = aws_instance.this.id
  vpc      = true
  tags     = local.tags
}

data "aws_iam_policy_document" "trust" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name               = "${var.instance_name}-${random_id.id.hex}"
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags = merge({ Name="ec2instance-${var.instance_name}" }, local.tags, var.custom_tags)
}

resource "aws_iam_role_policy" "custom" {
  for_each = var.custom_policies

  name   = element(split(".", basename(each.value)), 0)
  policy = file(each.value)
  role   = aws_iam_role.instance.id
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = local.managed_policies

  role       = aws_iam_role.instance.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.instance_name}-${random_id.id.hex}"
  role = aws_iam_role.instance.name
}

resource "aws_security_group" "this" {
  name = "${var.instance_name}-${random_id.id.hex}"
  description = "EC2 instance - ${var.instance_name}"
  vpc_id = var.vpc

  dynamic "ingress" {
    for_each = var.inbound_security_rules

    content {
      from_port = ingress.value.port == -1 ? 0 : ingress.value.port
      to_port = ingress.value.port == -1 ? 65535 : ingress.value.port
      protocol = ingress.value.protocol
      cidr_blocks = ingress.value.source
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.outbound_security_rules

    content {
      from_port = egress.value.port == -1 ? 0 : egress.value.port
      to_port = egress.value.port == -1 ? 65535 : egress.value.port
      protocol = egress.value.protocol
      cidr_blocks = egress.value.destination
      description = egress.value.description
    }
  }

  tags = merge({ Name="ec2instance-${var.instance_name}" }, local.tags, var.custom_tags)
}

resource "aws_instance" "this" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.keypair
  iam_instance_profile   = aws_iam_instance_profile.this.name
  vpc_security_group_ids = concat([aws_security_group.this.id], var.security_groups)
  subnet_id              = var.subnet

  root_block_device {
    delete_on_termination = true
    volume_size = var.volume_size
  }

  tags = merge({Name = var.instance_name}, local.tags, var.custom_tags)

  lifecycle {
    create_before_destroy = true
  }
}
