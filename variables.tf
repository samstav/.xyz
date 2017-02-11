variable "aws_region" {
  default = "us-east-1"
}

variable "domain" {
  type = "string"
}

variable "mailgun_api_key" {
  type = "string"
}

variable "mailgun_smtp_password" {
  type = "string"
}

variable "record_ttl" {
  default = 300
}
