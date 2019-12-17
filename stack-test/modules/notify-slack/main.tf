locals {
  # Set default tags
  tags = {
    project     = var.project_name
    env         = var.environment
    owner       = var.project_owner
    built-using = "terraform"
  }
}

resource "random_id" "id" {
  byte_length = 4
}

resource "aws_sns_topic" "this" {
  name         = "slack-${random_id.id.hex}"
  display_name = "Slack notifications"
  tags         = merge({ Name="slack-${var.project_name}" }, local.tags, var.custom_tags)
}

resource "aws_sns_topic_subscription" "this" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "lambda"
  endpoint  = module.notify_slack_lambda.function_arn
}

module "notify_slack_lambda" {
  source = "../lambda"

  s3_bucket        = var.s3_bucket
  function_name    = "slack-${var.project_name}-${var.environment}"
  function_source  = "../source/notify-slack"
  function_runtime = "python3.7"
  handler_config   = { module="main", function="handler"}
  custom_tags      = merge(local.tags, var.custom_tags)

  aws_managed_policies = [
    "AWSLambdaBasicExecutionRole"
  ]
}

resource "aws_lambda_permission" "notify_slack" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.notify_slack_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.this.arn
}
