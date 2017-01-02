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

