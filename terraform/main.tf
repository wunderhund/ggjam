provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

# Account
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}