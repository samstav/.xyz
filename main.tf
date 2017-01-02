provider "aws" {
  region = "${var.aws_region}"
}

provider "mailgun" {
  api_key = "${var.mailgun_api_key}"
}

module "melon" {
  source                = "github.com/samstav/tf_mailgun_aws"
  domain                = "${var.domain}"
  mailgun_smtp_password = "${var.mailgun_smtp_password}"
}
