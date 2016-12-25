variable "mailgun_smtp_password" {
  type = "string"
}

variable "mailgun_api_key" {
  type = "string"
}

variable "domain" {
  type = "string"
}

variable "mailgun_spam_action" {
  default = "tag"
}

variable "mailgun_wildcard" {
  default = true
}

variable "tf_remote_backend_bucket_prefix" {
  default = "melon-terraform-state"
}

variable "tf_remote_backend_key" {
  default = "melon-terraform.tfstate"
}

# Set this to 0 if you are using a local tfstate file.
variable "tf_remote_backend" {
  default = 1
}

variable "record_ttl" {
  default = 300
}

variable "aws_region" {
  default = "us-east-1"
}
