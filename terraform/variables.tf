variable "profile" {
  type = string
}

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "base_tags" {
  type = map
  default = {
    "project" = "ggjam"
  }
}

# S3 Buckets
variable "site_name" {
  type = string
}

variable "content_s3_bucket" {
  type = string
}

# Ghost Variables
variable "ghostdb_user" {
  type    = string
  default = "ghost"
}

variable "ghostdb_pass" {
  type = string
}

variable "ghostdb_database" {
  type    = string
  default = "ghost"
}

variable "ghostdb_client" {
  type    = string
  default = "mysql"
}

# Jumpbox Configuration
variable "jumpbox_access" {
  type = list
}

variable "jumpbox_key" {
  type = string
}

variable "ghost_api_key" {
  type = string
}

variable "ghost_port" {
  type    = string
  default = "2368"
}

variable "gatsby_repo" {
  type    = string
  default = "https://github.com/TryGhost/gatsby-starter-ghost.git"
}

# GitHub Variables
variable "github_personal_token" {
  type    = string
  default = ""
}

variable "github_secret_string" {
  type    = string
  default = "swordfish"
}

variable "github_owner" {
  type    = string
  default = ""
}
