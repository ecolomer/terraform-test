provider "aws" {
  region = "eu-west-1"
  version = "~> 2.28"
}

variable "terraform_workspace_id" {
  type    = string
  default = "terraform-test"
  description = "TF Cloud workspace"
}

terraform {
  required_version = ">= 0.12"
  backend "remote" {
    organization = "escherlab"

    workspaces {
      name = var.terraform_workspace_id
    }
  }
}
