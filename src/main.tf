resource "aws_s3_bucket" "demo" {
  bucket = "demo-bucket"
  acl    = "public-read"
}

resource "aws_s3_bucket" "demo2" {
  bucket = "demo-bucket-2"
  acl    = "public-read"
}

resource "aws_security_group" "allow_all" {
  name = "allow_all"
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0.0.0.0"]
  }
}
