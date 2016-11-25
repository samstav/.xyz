provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_s3_bucket" "tf_remote_config_bucket" {
  count  = "${var.tf_remote_backend}"
  bucket = "${var.tf_remote_backend_bucket_prefix}-${var.domain}"

  versioning {
    enabled = true
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

provider "mailgun" {
  api_key = "${var.mailgun_api_key}"
}

resource "mailgun_domain" "this" {
  name          = "${var.domain}"
  smtp_password = "${var.mailgun_smtp_password}"
  spam_action   = "${var.mailgun_spam_action}"
  wildcard      = "${var.mailgun_wildcard}"
}

resource "aws_route53_zone" "this" {
  name          = "${var.domain}"
  comment       = "Domain with mailgun mail managed by terraform."
  force_destroy = true
}

resource "aws_route53_record" "mailgun_sending_records" {

  # This is not allowed (yet), see terraform#1497, hard-coding for now.
  #  count   = "${length(mailgun_domain.this.sending_records)}"
  count = 3

  zone_id = "${aws_route53_zone.this.zone_id}"
  name    = "${element(mailgun_domain.this.sending_records, count.index)}.name"
  type    = "${element(mailgun_domain.this.sending_records, count.index)}.record_type"
  ttl     = "${var.record_ttl}"
  records = ["${element(mailgun_domain.this.sending_records, count.index)}.value"]
}

resource "aws_route53_record" "mailgun_receiving_records" {

  # This is not allowed (yet), see terraform#1497, hard-coding for now.
  #  count   = "${length(mailgun_domain.this.receiving_records)}"
  count = 2

  zone_id = "${aws_route53_zone.this.zone_id}"
  name    = "${element(mailgun_domain.this.receiving_records, count.index)}.name"
  type    = "${element(mailgun_domain.this.receiving_records, count.index)}.record_type"
  ttl     = "${var.record_ttl}"
  records = ["${element(mailgun_domain.this.receiving_records, count.index)}.priority ${element(mailgun_domain.this.receiving_records, count.index)}.value"]
}

output "receiving_records" {
  value = ["${aws_route53_record.mailgun_receiving_records.*.fqdn}"]
}

output "sending_records" {
  value = ["${aws_route53_record.mailgun_sending_records.*.fqdn}"]
}
