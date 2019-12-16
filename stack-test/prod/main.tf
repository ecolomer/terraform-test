locals {
  env           = "prod"
  vpc_id        = "vpc-2800f04f"
  subnets       = [ "subnet-87b14ce0", "subnet-c10e029a" ]
  project_name  = "rds-monitor"
  project_owner = "infrastructure"
  s3_bucket     = "ec-lambda-deploy"

  tags = {
    project     = local.project_name
    env         = local.env
    owner       = local.project_owner
    built-using = "terraform-test"
  }
}

module "notify_slack" {
  source = "../modules/notify-slack"

  s3_bucket     = local.s3_bucket
  project_name  = local.project_name
  project_owner = local.project_owner
  environment   = local.env
  custom_tags   = local.tags
}

module "aurora_monitor" {
  source = "../modules/aurora-monitor"

  s3_bucket       = local.s3_bucket
  project_name    = local.project_name
  project_owner   = local.project_owner
  environment     = local.env
  vpc             = local.vpc_id
  subnets         = local.subnets
  slack_sns_topic = module.notify_slack.sns_topic_arn
  custom_tags     = local.tags
}

