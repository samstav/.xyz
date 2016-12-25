provider "aws" {
  region = "${var.aws_region}"
}

provider "mailgun" {
  api_key = "${var.mailgun_api_key}"
}

resource "aws_s3_bucket" "tf_remote_config_bucket" {
  lifecycle {
    prevent_destroy = true
  }

  count  = "${var.tf_remote_backend}"
  bucket = "${var.tf_remote_backend_bucket_prefix}-${replace(var.domain, ".", "-dot-") }"

  versioning {
    enabled = true
  }
}

# This might be useful at some point, for referencing values in the remote state.
data "terraform_remote_state" "this" {
  backend = "s3"

  config {
    bucket  = "${var.tf_remote_backend_bucket_prefix}-${replace(var.domain, ".", "-dot-") }"
    key     = "${var.tf_remote_backend_key}"
    region  = "${var.aws_region}"
    encrypt = 1
  }
}

output "tf_config_s3_bucket_id" {
  value = "${aws_s3_bucket.tf_remote_config_bucket.id}"
}

output "tf_config_s3_bucket_arn" {
  value = "${aws_s3_bucket.tf_remote_config_bucket.arn}"
}

output "tf_config_s3_bucket_region" {
  value = "${aws_s3_bucket.tf_remote_config_bucket.region}"
}

resource "mailgun_domain" "this" {
  name          = "${var.domain}"
  smtp_password = "${var.mailgun_smtp_password}"
  spam_action   = "${var.mailgun_spam_action}"
  wildcard      = "${var.mailgun_wildcard}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_zone" "this" {
  name          = "${var.domain}"
  comment       = "Domain with mailgun mail managed by terraform."
  force_destroy = true
}

output {
  value = "${aws_route53_zone.this.zone_id}"
}

output {
  # Be sure to check this output and set using the UpdateDomainNameservers API
  value = "${aws_route53_zone.this.name_servers}"
}

resource "aws_route53_record" "mailgun_sending_record_0" {
  zone_id = "${aws_route53_zone.this.zone_id}"
  name    = "${mailgun_domain.this.sending_records.0.name}."
  ttl     = "${var.record_ttl}"
  type    = "${mailgun_domain.this.sending_records.0.record_type}"
  records = ["${mailgun_domain.this.sending_records.0.value}"]
}

resource "aws_route53_record" "mailgun_sending_record_1" {
  zone_id = "${aws_route53_zone.this.zone_id}"
  name    = "${mailgun_domain.this.sending_records.1.name}."
  ttl     = "${var.record_ttl}"
  type    = "${mailgun_domain.this.sending_records.1.record_type}"
  records = ["${mailgun_domain.this.sending_records.1.value}"]
}

resource "aws_route53_record" "mailgun_sending_record_2" {
  zone_id = "${aws_route53_zone.this.zone_id}"
  name    = "${mailgun_domain.this.sending_records.2.name}."
  ttl     = "${var.record_ttl}"
  type    = "${mailgun_domain.this.sending_records.2.record_type}"
  records = ["${mailgun_domain.this.sending_records.2.value}"]
}

resource "aws_route53_record" "mailgun_receiving_record_0" {
  zone_id = "${aws_route53_zone.this.zone_id}"
  name = "@"
  ttl     = "${var.record_ttl}"
  type = "${mailgun_domain.this.receiving_records.0.record_type}"
  records = ["${mailgun_domain.this.receiving_records.0.priority} ${mailgun_domain.this.receiving_records.0.value}"]

}

resource "aws_route53_record" "mailgun_receiving_record_1" {
  zone_id = "${aws_route53_zone.this.zone_id}"
  name = "@"
  ttl     = "${var.record_ttl}"
  type = "${mailgun_domain.this.receiving_records.1.record_type}"
  records = ["${mailgun_domain.this.receiving_records.1.priority} ${mailgun_domain.this.receiving_records.1.value}"]}
