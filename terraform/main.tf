# Providers
provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

provider "github" {
  version    = "~> 2.5"
  individual = true
  token      = var.github_personal_token
  # Uncomment when using GH Enterprise only:
  #organization = var.github_owner
}

provider "archive" {
  version = "~> 1.3"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

# Account Variables
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}