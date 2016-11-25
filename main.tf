provider "aws" {
  region = "${var.aws_region}"
}

provider "mailgun" {
  api_key = "${var.mailgun_api_key}"
}

resource "mailgun_domain" "this" {
  name = "${var.domain}"
  smtp_password = "${var.mailgun_smtp_password}"
  spam_action = "${var.mailgun_spam_action}"
  wildcard = "${var.mailgun_wildcard}"
}

resource "aws_route53_zone" "this" {
  name = "${var.domain}"
  comment = "Domain with mailgun mail managed by terraform."
  force_destroy = true
}

resource "aws_route53_record" "mailgun_verification_spf" {
  zone_id = "${aws_route53_zone.this.zone_id}"
  name = "${aws_route53_zone.this.name}"
  type = "TXT"
  ttl = 300
  records = ["${var.mailgun_spf_record_value}"]
}


resource "aws_route53_record" "mailgun_verification_spf" {
  zone_id = "${aws_route53_zone.this.zone_id}"
  name = "${aws_route53_zone.this.name}"
  type = "TXT"
  ttl = 300
  records = ["${var.mailgun_spf_record_value}"]
}

resource "aws_route53_record" "mailgun_verification_dkim" {
  zone_id = "${aws_route53_zone.this.zone_id}"
  name = "${var.mailgun_dkim_record_name}"
  type = "TXT"
  ttl = 300
  records = ["${var.mailgun_dkim_record_value}"]
}

resource "aws_route53_record" "mailgun_tracking" {
  zone_id = "${aws_route53_zone.this.zone_id}"
  name = "email"
  type = "CNAME"
  ttl = 300
  records = ["mailgun.org"]
}

resource "aws_route53_record" "mailgun_receiving_mxa" {
  zone_id = "${aws_route53_zone.this.zone_id}"
  name = "${aws_route53_zone.this.name}"
  type = "MX"
  ttl = 300
  records = ["10 mxa.mailgun.org"]
}

resource "aws_route53_record" "mailgun_receiving_mxb" {
  zone_id = "${aws_route53_zone.this.zone_id}"
  name = "${aws_route53_zone.this.name}"
  type = "MX"
  ttl = 300
  records = ["10 mxb.mailgun.org"]
}

