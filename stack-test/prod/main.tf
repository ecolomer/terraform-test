locals {
  env = "prod"
  vpc_id = "vpc-2800f04f"
  subnets = [ "subnet-87b14ce0", "subnet-c10e029a" ]

  tags = {
    project = "aurora-monitor"
    env = "prod"
    owner = "infrastructure",
    built-using = "terraform"
  }
}

resource "random_id" "id" {
  byte_length = 4
}

resource "aws_sns_topic" "notify_slack" {
  name = "notify-slack-${random_id.id.hex}"
  display_name = "Slack notifications"
  tags = local.tags
}

resource "aws_sns_topic_subscription" "notify_slack" {
  topic_arn = aws_sns_topic.notify_slack.arn
  protocol  = "lambda"
  endpoint  = module.notify_slack_lambda.function_arn
}

module "notify_slack_lambda" {
  source                 = "../../modules/lambda"

  s3_bucket = "ec-lambda-deploy"
  function_name = "notify-infrastructure-slack"
  function_source = "../source/notify-slack"
  function_runtime = "python3.7"
  handler_config = { module="main", function="handler"}
  custom_tags = local.tags

  aws_managed_policies = [
    "AWSLambdaBasicExecutionRole"
  ]
}

resource "aws_lambda_permission" "notify_slack" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.notify_slack_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.notify_slack.arn
}

module "aurora_monitor_lambda" {
  source                 = "../../modules/lambda"

  s3_bucket = "ec-lambda-deploy"
  function_name = "aurora-monitor"
  function_source = "../source/aurora-monitor"
  function_runtime = "python3.7"
  handler_config = { module="main", function="handler"}
  custom_tags = local.tags
  vpc_config = { vpc_id = local.vpc_id, subnets = local.subnets }

  aws_managed_policies = [
    "AWSLambdaVPCAccessExecutionRole"
  ]

  custom_policies = [
    "policies/secrets.json"
  ]

  env_vars = { SNS_SLACK_TOPIC = aws_sns_topic.notify_slack.arn }
}

resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name = "every-five-minutes"
  description = "Fires every five minutes"
  schedule_expression = "rate(5 minutes)"
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
