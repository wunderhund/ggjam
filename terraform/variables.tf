variable "profile" {
  type    = string
  default = "ggjam"
}

variable "region" {
  type = string
}

variable "base_tags" {
  type = map
  default = {
    "project" = "ggjam"
  }
}

variable "site_name" {
  type = string
}

variable "content_s3_bucket" {
  type = string
}