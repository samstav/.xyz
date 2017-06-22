terraform {
  backend "s3" {
    bucket = "terraform-state-samstav-dot-xyz"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "${var.aws_region}"
}

module "mailer" {
  source                = "github.com/samstav/tf_mailgun_aws"
  domain                = "${var.domain}"
  mailgun_smtp_password = "${var.mailgun_smtp_password}"
}

resource "aws_route53_record" "keybase_proof" {
  zone_id = "${module.mailer.zone_id}"
  name = "@"
  type = "TXT"
  ttl = 300
  records = ["keybase-site-verification=EKOkYRTN-0RW6PKIqAgJ2HzE7GF0r1CDZiVXcKf2azY"]
}
