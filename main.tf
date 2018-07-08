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

provider "mailgun" {
  api_key = "${var.mailgun_api_key}"
}

module "mailer" {
  source                = "github.com/samstav/tf_mailgun_aws"
  domain                = "samstav.xyz"
  mailgun_smtp_password = "${var.mailgun_smtp_password}"
}

resource "aws_route53_record" "keybase_proof" {
  zone_id = "${module.mailer.zone_id}"
  name = "@"
  type = "TXT"
  ttl = 300
  records = ["keybase-site-verification=EKOkYRTN-0RW6PKIqAgJ2HzE7GF0r1CDZiVXcKf2azY"]
}
