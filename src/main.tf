resource "aws_s3_bucket" "demo" {
  bucket = "demo-bucket"
  acl    = "public-read"
}

resource "aws_s3_bucket" "demo2" {
  bucket = "demo-bucket-2"
  acl    = "public-read"
}
