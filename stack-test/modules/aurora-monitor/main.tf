locals {
  # Set default tags
  tags = {
    project     = var.project_name
    env         = var.environment
    owner       = var.project_owner
    built-using = "terraform1"
  }
}

resource "random_id" "id" {
  byte_length = 4
}

data "aws_iam_policy_document" "allow_sns_publish" {
  statement {
    effect = "Allow"
    actions = ["SNS:Publish"]
    resources = [var.slack_sns_topic]
  }
}

resource "local_file" "foo" {
  content  = data.aws_iam_policy_document.allow_sns_publish.json
  filename = "${path.cwd}/policies/sns.json"
}

module "aurora_monitor_lambda" {
  source = "../lambda"

  s3_bucket        = var.s3_bucket
  function_name    = "${var.project_name}-${var.project_owner}-${var.environment}"
  function_source  = "../source/aurora-monitor"
  function_runtime = "python3.7"
  handler_config   = { module="main", function="handler"}
  custom_tags      = merge(local.tags, var.custom_tags)
  vpc_config = { vpc_id = var.vpc, subnets = var.subnets }

  aws_managed_policies = [
    "AWSLambdaVPCAccessExecutionRole"
  ]

  custom_policies = fileset(path.cwd, "policies/**")
  env_vars = { SNS_SLACK_TOPIC = var.slack_sns_topic }
}

resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name = "every-five-minutes-${random_id.id.hex}"
  description = "Fires every five minutes"
  schedule_expression = "rate(5 minutes)"
  tags = merge(local.tags, var.custom_tags)
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule = aws_cloudwatch_event_rule.every_five_minutes.name
  target_id = module.aurora_monitor_lambda.function_name
  arn = module.aurora_monitor_lambda.function_arn
}

resource "aws_lambda_permission" "allow_cloudwatch_events" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = module.aurora_monitor_lambda.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.every_five_minutes.arn
}
