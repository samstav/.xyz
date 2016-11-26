# melon
my domain stuff (dns, email/mailgun + aws route 53)

If you choose to use the S3 Remote Config for terraform,
you can import the bucket you created this to be managed
by terraform itself:

```
terraform import aws_s3_bucket.bucket melon-terraform-state-foo-dot-com
```

There's probably a better way to bootstrap this by
using `terraform plan -target`, creating the s3 bucket
defined in main.tf, and then migrating the state to a
remote config that lives in that same bucket.
