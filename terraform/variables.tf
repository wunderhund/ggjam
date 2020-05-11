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

variable "ghostdb_user" {
  type    = string
  default = "ghost"
}

variable "ghostdb_pass" {
  type = string
}

variable "jumpbox_access" {
  type = list
}

variable "jumpbox_key" {
  type = string
}

variable "github_personal_token" {
  type    = string
  default = ""
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

variable "github_secret_string" {
  type    = string
  default = "swordfish"
}

variable "github_owner" {
  type = string
}

variable "website_s3_bucket" {
  type = string
}

variable "content_s3_bucket" {
  type = string
}