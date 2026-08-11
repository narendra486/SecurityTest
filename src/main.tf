terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  # BAD: hardcoded credentials
  access_key = "AKIAIOSFODNN7EXAMPLE"
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
}

# ============================================================
# VPC
# ============================================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vulnerable-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ============================================================
# SECURITY GROUP
# ============================================================

resource "aws_security_group" "web" {
  name        = "vulnerable-web-sg"
  description = "Intentionally vulnerable security group"
  vpc_id      = aws_vpc.main.id

  # BAD: SSH open to the entire Internet
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # BAD: RDP open to the Internet
  ingress {
    description = "RDP from anywhere"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # BAD: PostgreSQL exposed
  ingress {
    description = "Postgres from anywhere"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # BAD: MySQL exposed
  ingress {
    description = "MySQL from anywhere"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # BAD: All ports exposed
  ingress {
    description = "All TCP"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # BAD: unrestricted egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ============================================================
# S3
# ============================================================

resource "aws_s3_bucket" "documents" {
  bucket = "company-sensitive-documents"

  tags = {
    Environment = "production"
    Data        = "sensitive"
  }
}

# BAD: public ACL
resource "aws_s3_bucket_acl" "documents" {
  bucket = aws_s3_bucket.documents.id
  acl    = "public-read"
}

# BAD: public access block disabled
resource "aws_s3_bucket_public_access_block" "documents" {
  bucket = aws_s3_bucket.documents.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# BAD: no encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ============================================================
# S3 WEBSITE
# ============================================================

resource "aws_s3_bucket" "website" {
  bucket = "public-company-website"

  tags = {
    Environment = "production"
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = "*"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}

# ============================================================
# IAM
# ============================================================

resource "aws_iam_user" "admin" {
  name = "application-admin"
}

# BAD: AdministratorAccess
resource "aws_iam_user_policy_attachment" "admin" {
  user       = aws_iam_user.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# BAD: overly permissive custom policy
resource "aws_iam_policy" "application" {
  name = "application-full-access"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
}

# BAD: wildcard resource
resource "aws_iam_role_policy" "application" {
  role = aws_iam_role.application.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:*",
          "ec2:*",
          "rds:*"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "application" {
  name = "application-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          AWS = "*"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ============================================================
# EC2
# ============================================================

resource "aws_instance" "web" {
  ami           = "ami-1234567890abcdef0"
  instance_type = "t3.large"

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  # BAD: public IP
  associate_public_ip_address = true

  # BAD: disable metadata protections
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  # BAD: hardcoded password
  user_data = <<-EOF
    #!/bin/bash

    echo "admin_password=SuperSecretPassword123" > /tmp/config

    export DATABASE_PASSWORD="MyDatabasePassword123"

    apt-get update
    apt-get install -y curl wget

    curl http://example.com/install.sh | bash
  EOF

  tags = {
    Name = "production-web"
  }
}

# ============================================================
# EBS
# ============================================================

resource "aws_ebs_volume" "data" {
  availability_zone = "us-east-1a"
  size              = 100

  # BAD: encryption disabled
  encrypted = false

  tags = {
    Name = "sensitive-data"
  }
}

# ============================================================
# RDS
# ============================================================

resource "aws_db_instance" "database" {
  identifier = "production-database"

  engine         = "postgres"
  engine_version = "15"

  instance_class        = "db.t3.medium"
  allocated_storage     = 100
  max_allocated_storage = 500

  username = "admin"

  # BAD: hardcoded database password
  password = "SuperSecretDatabasePassword123"

  # BAD: encryption disabled
  storage_encrypted = false

  # BAD: publicly accessible
  publicly_accessible = true

  # BAD: deletion protection disabled
  deletion_protection = false

  # BAD: backups disabled
  backup_retention_period = 0

  # BAD: skip final snapshot
  skip_final_snapshot = true

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  tags = {
    Environment = "production"
  }
}

# ============================================================
# REDIS / ELASTICACHE
# ============================================================

resource "aws_elasticache_cluster" "redis" {
  cluster_id = "production-redis"

  engine         = "redis"
  engine_version = "7.0"

  node_type = "cache.t3.micro"

  num_cache_nodes = 1

  # BAD: no encryption in transit
  transit_encryption_enabled = false

  # BAD: no encryption at rest
  at_rest_encryption_enabled = false

  security_group_ids = [
    aws_security_group.web.id
  ]
}

# ============================================================
# LOAD BALANCER
# ============================================================

resource "aws_lb" "application" {
  name = "vulnerable-alb"

  load_balancer_type = "application"

  subnets = [
    aws_subnet.public.id
  ]

  security_groups = [
    aws_security_group.web.id
  ]

  # BAD: access logs disabled
  access_logs {
    enabled = false
    bucket  = aws_s3_bucket.documents.id
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Hello"
      status_code  = "200"
    }
  }
}

# ============================================================
# EKS
# ============================================================

resource "aws_eks_cluster" "main" {
  name = "vulnerable-cluster"

  role_arn = aws_iam_role.application.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.public.id,
      aws_subnet.private.id
    ]

    # BAD: public API endpoint
    endpoint_public_access = true

    # BAD: unrestricted public CIDR
    public_access_cidrs = [
      "0.0.0.0/0"
    ]
  }

  # BAD: logging disabled
  enabled_cluster_log_types = []
}

# ============================================================
# KMS
# ============================================================

resource "aws_kms_key" "application" {
  description = "Application encryption key"

  # BAD: key rotation disabled
  enable_key_rotation = false

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowEveryone"
        Effect = "Allow"

        Principal = "*"

        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

# ============================================================
# CLOUDTRAIL
# ============================================================

resource "aws_cloudtrail" "main" {
  name = "production-trail"

  s3_bucket_name = aws_s3_bucket.documents.id

  # BAD: log file validation disabled
  enable_log_file_validation = false

  # BAD: CloudTrail disabled for global service events
  include_global_service_events = false

  # BAD: management events disabled
  event_selector {
    read_write_type           = "WriteOnly"
    include_management_events = false
  }
}

# ============================================================
# CLOUDWATCH LOG GROUP
# ============================================================

resource "aws_cloudwatch_log_group" "application" {
  name = "/application/production"

  # BAD: logs retained for too long / uncontrolled
  retention_in_days = 0

  # BAD: KMS encryption not configured
}

# ============================================================
# SNS
# ============================================================

resource "aws_sns_topic" "alerts" {
  name = "production-alerts"

  # BAD: encryption not configured
}

resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = "*"

        Action = "SNS:Publish"

        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}

# ============================================================
# SQS
# ============================================================

resource "aws_sqs_queue" "jobs" {
  name = "production-jobs"

  # BAD: server-side encryption disabled
  sqs_managed_sse_enabled = false

  # BAD: very long retention
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue_policy" "jobs" {
  queue_url = aws_sqs_queue.jobs.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = "*"

        Action = "sqs:*"

        Resource = aws_sqs_queue.jobs.arn
      }
    ]
  })
}

# ============================================================
# SECRETS
# ============================================================

resource "aws_secretsmanager_secret" "database" {
  name = "production/database"

  # BAD: recovery disabled
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id

  # BAD: secret stored directly in Terraform
  secret_string = jsonencode({
    username = "admin"
    password = "SuperSecretPassword123"
    host     = "production-db.internal"
  })
}

# ============================================================
# LAMBDA
# ============================================================

resource "aws_lambda_function" "processor" {
  function_name = "production-processor"

  filename = "lambda.zip"

  handler = "index.handler"
  runtime = "nodejs20.x"

  role = aws_iam_role.application.arn

  environment {
    variables = {
      DATABASE_PASSWORD = "SuperSecretPassword123"
      API_KEY            = "sk_test_123456789"
      JWT_SECRET         = "secret"
    }
  }

  # BAD: tracing disabled
  tracing_config {
    mode = "PassThrough"
  }
}

# BAD: Lambda publicly invokable
resource "aws_lambda_permission" "public" {
  statement_id = "AllowPublicInvoke"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.processor.function_name

  principal = "*"
}

# ============================================================
# API GATEWAY
# ============================================================

resource "aws_api_gateway_rest_api" "api" {
  name = "vulnerable-api"

  endpoint_configuration {
    types = ["EDGE"]
  }
}

# ============================================================
# DYNAMODB
# ============================================================

resource "aws_dynamodb_table" "users" {
  name         = "production-users"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # BAD: point-in-time recovery disabled
  point_in_time_recovery {
    enabled = false
  }

  # BAD: deletion protection disabled
  deletion_protection_enabled = false

  # BAD: server-side encryption disabled
  server_side_encryption {
    enabled = false
  }
}

# ============================================================
# OUTPUTS
# ============================================================

output "database_password" {
  value     = aws_db_instance.database.password
  sensitive = false
}

output "secret_value" {
  value     = aws_secretsmanager_secret_version.database.secret_string
  sensitive = false
}

output "access_key" {
  value     = "AKIAIOSFODNN7EXAMPLE"
  sensitive = false
}
