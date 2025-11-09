terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    encrypt = true
    bucket = "mothersect-tf-state"
    dynamodb_table = "mothersect-tf-state-lock"
    key    = "turboman"
    region = "us-east-1"
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
    name                   = aws_cloudfront_distribution.turboman.domain_name
    zone_id                = aws_cloudfront_distribution.turboman.hosted_zone_id
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

resource "aws_acm_certificate" "turboman" {
  domain_name       = var.domain_url
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "turboman_validation" {
  for_each = {
    for dvo in aws_acm_certificate.turboman.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

resource "aws_cloudfront_distribution" "turboman" {
  origin {
    domain_name              = aws_s3_bucket.tm_bucket.bucket_domain_name
    origin_id                = aws_s3_bucket.tm_bucket.id
  }

  enabled             = true
  is_ipv6_enabled     = false
  comment             = "Some comment"
  default_root_object = "index.html"

  aliases = [var.domain_url]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.tm_bucket.id
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "all"
      }
    }
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.turboman.arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}