provider "aws" {
  region = var.aws_region
  version = "~> 2.28"
}

terraform {
  required_version = ">= 0.12"
}
