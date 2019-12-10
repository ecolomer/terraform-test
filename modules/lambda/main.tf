locals {
  environment_map = var.env_vars == null ? [] : [var.env_vars]

  tags = {
    project = var.function_name
    env = "dev"
    owner = var.function_name
    built-using = "terraform"
  }
}

# Used to get the current AWS Account Id
data "aws_caller_identity" "current" {}

# Used to get the current AWS Region
data "aws_region" "current" {}

# Used to generate "unique" names
resource "random_id" "id" {
  byte_length = 4
}

# This deployment package is used to initialize the Lambda function
# If dependencies in the code need to be packaged, use GitHub Actions
data "archive_file" "zip" {
  type        = "zip"
  source_dir  = var.function_source
  output_path = "${var.function_name}.zip"
}

resource "aws_s3_bucket_object" "package" {
  bucket = var.s3_bucket
  key    = "${var.function_name}.zip"
  source = data.archive_file.zip.output_path
}

data "aws_iam_policy_document" "trust" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "function" {
  name               = "${var.function_name}-${random_id.id.hex}"
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags = merge(local.tags, var.custom_tags, { Name="lambda-execution-${var.function_name}" })
}

data "aws_iam_policy_document" "default" {
  statement {
    effect = "Allow"
    actions = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    effect = "Allow"
    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.function_name}:*"]
  }
}

resource "aws_iam_role_policy" "default" {
  name   = "DefaultAccess"
  policy = data.aws_iam_policy_document.default.json
  role   = aws_iam_role.function.id
}

resource "aws_iam_role_policy" "custom" {
  for_each = var.custom_policies

  name   = element(split(".", basename(each.value)), 0)
  policy = file(each.value)
  role   = aws_iam_role.function.id
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = var.aws_managed_policies

  role       = aws_iam_role.function.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/${each.value}"
}

resource "aws_security_group" "this" {
  count = var.vpc_config.vpc_id != null ? 1 : 0
  name = "${var.function_name}-${random_id.id.hex}"
  description = "Lambda - ${var.function_name}"
  vpc_id = var.vpc_config.vpc_id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all egress traffic"
  }

  tags = merge(local.tags, var.custom_tags, { Name="lambda-${var.function_name}" })
}

resource "aws_lambda_function" "this" {
  s3_bucket        = var.s3_bucket
  s3_key           = "${var.function_name}.zip"
  source_code_hash = data.archive_file.zip.output_base64sha256
  function_name    = var.function_name
  role             = aws_iam_role.function.arn
  handler          = "${var.handler_config.module}.${var.handler_config.function}"
  runtime          = var.function_runtime
  memory_size      = var.function_memory
  timeout          = var.function_timeout

  dynamic "environment" {
    for_each = local.environment_map

    content {
      variables = environment.value
    }
  }

  vpc_config {
    security_group_ids = var.vpc_config.vpc_id != null ? [aws_security_group.this[0].id] : []
    subnet_ids = var.vpc_config.subnets
  }

  tags = merge(local.tags, var.custom_tags)
}