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
  type = string
}

variable "ghost_api_key" {
  type = string
}

variable "ghost_port" {
  type    = string
  default = "2368"
}