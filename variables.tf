
variable "mailgun_api_key" {
  type = "string"
}

variable "mailgun_spf_record_value" {
  default = "v=spf1 include:mailgun.org ~all"
}

variable "mailgun_dkim_record_name" {
  default = "smtp._domainkey"
}

variable "mailgun_dkim_record_value" {
  type = "string"
}

variable "mailgun_domain_smtp_password" {
  type = "string"
}

variable "mailgun_domain_spam_action" {
  default = "tag"
}

variable "mailgun_domain_wildcard" {
  default = true
}

variable "domain" {
  type = "string"
}

variable "aws_region" {
  default = "us-west-2"
}
