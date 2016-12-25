# melon
samstav.xyz stuff (dns, email/mailgun + aws route 53)

I prefer using [s3 remote state for terraform](https://www.terraform.io/docs/state/remote/s3.html) instead of leaving state on your local machine. In addition to being able to make infra changes via CI (e.g. CircleCI), this has the added benefit of easy tf state rollbacks via S3 bucket versioning.

Bootsrap your remote state bucket like so:

```
$ terraform plan -out=remote-config.plan -target=aws_s3_bucket.tf_remote_config_bucket
$ terraform apply remote-config.plan
```

Otherwise: If you do choose to use the S3 Remote Config
for terraform, you can instead import an _existing_ bucket:

```
# instead of the foo-dot-com suffix, if your domain
# is johnsmith.net use melon-terraform-state-johnsmith-dot-net
$ terraform import aws_s3_bucket.bucket melon-terraform-state-foo-dot-com
```

Terraform autloads `terraform.tfvars.json` variable files as well,
as of https://github.com/hashicorp/terraform/pull/1093
so run the tfvars command like so:

```
./melon.py tfvars foo.com > terraform.tfvars.json
```

Then

```
terraform plan -out=melon.plan
terraform apply melon.plan
```
