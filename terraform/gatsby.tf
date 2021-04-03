resource "aws_cloudwatch_log_group" "gatsby" {
  name = "/aws/cloudwatch/gatsby"
}

resource "aws_s3_bucket" "ggjam-website" {
  bucket        = var.site_name
  acl           = "public-read"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

data "aws_iam_policy_document" "ggjam-website-bucket-policy" {
  statement {
    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.ggjam-website.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "ggjam-website-bucket-policy" {
  bucket = aws_s3_bucket.ggjam-website.id
  policy = data.aws_iam_policy_document.ggjam-website-bucket-policy.json
}

data "aws_iam_policy_document" "ggjam-website" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.ggjam-website.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "ggjam-website" {
  name        = "ggjam-website"
  description = "Website S3 bucket IAM policy"
  path        = "/service-role/"
  policy      = data.aws_iam_policy_document.ggjam-website.json
}

# CloudFront Distribution

locals {
  s3_origin_id = "S3-${var.site_name}"
}

resource "aws_cloudfront_distribution" "ggjam_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  default_root_object = "index.html"

  aliases = [var.site_name]

  origin {
    domain_name = aws_s3_bucket.ggjam-website.website_endpoint
    origin_id   = local.s3_origin_id

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:925412914118:certificate/d2e793e8-535e-420d-a1d6-90bd350a7f6e"
    minimum_protocol_version = "TLSv1.2_2018"
    ssl_support_method       = "sni-only"
  }
}