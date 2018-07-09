#
# Backend Configuration
#

terraform {
  backend "s3" {
    bucket = "terraform-state-stav-dot-xyz"
    # consider moving this into a states/
    key    = "terraform.tfstate"
    region = "us-west-2"
    encrypt = true
  }
}

# This is the infra code for terraform itself (state bucket, lock table, etc.)
module "backend" {
  source = "github.com/samstav/terraform-aws-backend"
  backend_bucket = "terraform-state-stav-dot-xyz"
  dynamodb_lock_table_enabled = 0
}


#
# Variables
#

variable "mailgun_smtp_password" {
  type = "string"
}

variable "mailgun_api_key" {
  type = "string"
}

#
# Providers
#

provider "aws" {
  region = "us-west-2"
}

provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}

provider "mailgun" {
  api_key = "${var.mailgun_api_key}"
}

#
# Resources
#

resource "aws_route53_zone" "stav-dot-xyz" {
  name          = "stav.xyz."
}

resource "aws_route53_zone" "samstav-dot-xyz" {
  name          = "samstav.xyz."
}

module "mailer" {
  source                = "github.com/samstav/terraform-mailgun-aws?ref=v2.0.1a"
  domain                = "samstav.xyz"
  mailgun_smtp_password = "${var.mailgun_smtp_password}"
  zone_id               = "${aws_route53_zone.samstav-dot-xyz.zone_id}"
}

module "stav-dot-xyz-mailer" {
  source                = "github.com/samstav/terraform-mailgun-aws?ref=v2.0.1a"
  domain                = "stav.xyz"
  mailgun_smtp_password = "${var.mailgun_smtp_password}"
  zone_id               = "${aws_route53_zone.stav-dot-xyz.zone_id}"
}

resource "aws_route53_record" "keybase_proof" {
  zone_id = "${module.mailer.zone_id}"
  name = "_keybase.samstav.xyz"
  type = "TXT"
  ttl = 300
  records = ["keybase-site-verification=EKOkYRTN-0RW6PKIqAgJ2HzE7GF0r1CDZiVXcKf2azY"]
}

resource "aws_acm_certificate" "stav-dot-xyz-wildcard" {
  provider = "aws.virginia"
  domain_name       = "*.stav.xyz"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "stav-dot-xyz-acm_validation" {
  name = "${aws_acm_certificate.stav-dot-xyz-wildcard.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.stav-dot-xyz-wildcard.domain_validation_options.0.resource_record_type}"
  zone_id = "${aws_route53_zone.stav-dot-xyz.zone_id}"
  records = ["${aws_acm_certificate.stav-dot-xyz-wildcard.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}

