locals {
  env = "prod"
  vpc_id = "vpc-2800f04f"
  subnets = [ "subnet-87b14ce0", "subnet-c10e029a" ]

  tags = {
    project = "rds-monitor"
    env = "prod"
    owner = "infrastructure",
    built-using = "terraform"
  }
}

module "rds-monitor" {
  source                 = "../../modules/lambda"
  aws_managed_policies = [
    "AWSLambdaVPCAccessExecutionRole"
  ]
  custom_policies = [
    "policies/secrets.json"
  ]
  s3_bucket = "ec-lambda-deploy"
  function_name = "rds-monitor"
  function_source = "../source/"
  function_runtime = "python3.7"
  handler_config = { module="main", function="handler"}
  custom_tags = local.tags
  vpc_config = { vpc_id = local.vpc_id, subnets = local.subnets }
}

resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name = "every-five-minutes"
  description = "Fires every five minutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule = aws_cloudwatch_event_rule.every_five_minutes.name
  target_id = "rds-monitor"
  arn = module.rds-monitor.function_arn
}

resource "aws_lambda_permission" "allow_cloudwatch_events" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = "rds-monitor"
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.every_five_minutes.arn
}

resource "aws_sns_topic" "sns_notification" {
  name = "sns-notification"
}

data "aws_secretsmanager_secret" "slack_url" {
  name = "slack-url"
}

data "aws_secretsmanager_secret_version" "slack_url" {
  secret_id = data.aws_secretsmanager_secret.slack_url.id
}

module "notify_slack" {
  source = "terraform-aws-modules/notify-slack/aws"
  version = "2.3.0"

  sns_topic_name   = aws_sns_topic.sns_notification.name
  create_sns_topic = false

  slack_webhook_url = data.aws_secretsmanager_secret_version.slack_url.secret_string
  slack_channel     = "@eleatzar.colomer"
  slack_username    = "eleatzar.colomer"

  tags = {
    Name = "notify-slack-simple"
  }
}