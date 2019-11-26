locals {
  env = "prod"
  vpc_id = "vpc-2800f04f"
  custom_tags = {
    env = local.env
  }
}

module "rds-monitor" {
  source = "../../modules/lambda"
  aws_managed_policies = [
    "AWSLambdaVPCAccessExecutionRole"
  ]
  s3_bucket = "ec-lambda-deploy"
  function_name = "rds-monitor-liveness"
  function_source = "source/"
  function_runtime = "python3.7"
  handler_config = { module="main", function="lambda_handler"}
  custom_tags = merge(local.custom_tags, {project = "rds-monitor"})
}

#resource "aws_cloudwatch_event_rule" "every_five_minutes" {
#  name = "every-five-minutes"
#  description = "Fires every five minutes"
#  schedule_expression = "rate(5 minutes)"
#}
#
#resource "aws_cloudwatch_event_target" "check_foo_every_five_minutes" {
#  rule = "${aws_cloudwatch_event_rule.every_five_minutes.name}"
#  target_id = "check_foo"
#  arn = "${aws_lambda_function.check_foo.arn}"
#}
#
#resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_foo" {
#  statement_id = "AllowExecutionFromCloudWatch"
#  action = "lambda:InvokeFunction"
#  function_name = "${aws_lambda_function.check_foo.function_name}"
#  principal = "events.amazonaws.com"
#  source_arn = "${aws_cloudwatch_event_rule.every_five_minutes.arn}"
#}