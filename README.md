# mail
my email stuff (mailgun + aws route 53)


If you choose to use the S3 Remote Config for terraform,
you can import the bucket you created this to be managed
by terraform itself:

```
terraform import aws_s3_bucket.bucket melon-terraform-state-foo-dot-com
```
