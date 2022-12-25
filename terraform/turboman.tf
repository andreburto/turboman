terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Can possibly be replaced with the template module.
# https://registry.terraform.io/modules/hashicorp/dir/template/latest
locals {
  type_by_ext = {
    "css"  = "text/css"
    "html" = "text/html"
    "js"   = "application/javascript"
    "json" = "application/json"
    "txt"  = "text/plain"
  }
}

resource "aws_s3_bucket" "tm_bucket" {
  bucket = var.domain_url
  acl    = "public-read"

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "PublicReadForGetBucketObjects",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${var.domain_url}/*"
    }
  ]
}
EOF

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Name        = var.domain_url
    Environment = "development"
  }
}

# DNS stuff
resource "aws_route53_record" "turboman" {
  zone_id = var.zone_id
  name    = "${var.domain_url}."
  type    = "A"

  alias {
    name                   = aws_s3_bucket.tm_bucket.website_domain
    zone_id                = aws_s3_bucket.tm_bucket.hosted_zone_id
    evaluate_target_health = false
  }
}

# The image files to upload.
resource "aws_s3_bucket_object" "image" {
  for_each     = fileset("${var.base_path}/${var.image_dir}", "*.jpg")
  bucket       = aws_s3_bucket.tm_bucket.bucket
  content_type = "image/jpeg"
  key          = each.value
  source       = "${var.base_path}/${var.image_dir}/${each.value}"
  etag         = filemd5("${var.base_path}/${var.image_dir}/${each.value}")
}

# Load the source files.
resource "aws_s3_bucket_object" "index" {
  for_each     = fileset("${var.base_path}/${var.source_dir}", "*")
  content_type = lookup(local.type_by_ext, split(".", each.value)[1], local.type_by_ext["txt"])
  bucket       = aws_s3_bucket.tm_bucket.bucket
  key          = each.value
  source       = "${var.base_path}/${var.source_dir}/${each.value}"
  etag         = filemd5("${var.base_path}/${var.source_dir}/${each.value}")
}
