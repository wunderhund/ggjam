resource "aws_cloudwatch_log_group" "gatsby" {
  name = "/aws/cloudwatch/gatsby"
}

resource "aws_s3_bucket" "ggjam-website" {
  bucket        = "ggjam.craigabutler.com"
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

resource "aws_iam_role" "ggjam-website-build" {
  name = "ggjam-website-build-service-role"
  path = "/service-role/"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

data "aws_iam_policy_document" "ggjam-website-build-policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      aws_cloudwatch_log_group.gatsby.arn
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]

    resources = [
      "${aws_s3_bucket.ggjam-website.arn}/*"
    ]
  }

  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "ec2:CreateNetworkInterfacePermission"
    ]

    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:Subnet"
      values = [aws_subnet.private-a.arn, aws_subnet.private-b.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:AuthorizedService"
      values = [
        "codebuild.amazonaws.com"
      ]
    }
  }

}

resource "aws_iam_policy" "codebuild" {
  name        = "ggjam-website-build-policy"
  description = "Codebuild IAM policy"
  path        = "/service-role/"
  policy      = data.aws_iam_policy_document.ggjam-website-build-policy.json
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.ggjam-website-build.name
  policy_arn = aws_iam_policy.codebuild.arn
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

resource "aws_iam_role_policy_attachment" "ggjam-website" {
  role       = aws_iam_role.ggjam-website-build.name
  policy_arn = aws_iam_policy.ggjam-website.arn
}

resource "aws_security_group" "gatsby" {
  name        = "gatsby"
  description = "Security Group for Gatsby build"
  vpc_id      = aws_vpc.ggjam.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge (
    {
      Name = "gatsby"
    },
    var.base_tags
  )
}

resource "aws_codebuild_project" "ggjam_frontend" {
  name          = "ggjam-frontend"
  description   = "Frontend static site generator for GGJAM"
  build_timeout = "60"
  service_role  = aws_iam_role.ggjam-website-build.arn

  artifacts {
    type = "S3"
    location = aws_s3_bucket.ggjam-website.bucket
  }

  cache {
    type = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "ARTIFACTS_BUCKET"
      value = aws_s3_bucket.ggjam-website.bucket
    }
  }

  logs_config {
    cloudwatch_logs {
      status     = "ENABLED"
      group_name = aws_cloudwatch_log_group.gatsby.name
    }
  }

  source {
    type = "GITHUB"
    location = "https://github.com/wunderhund/gatsby-starter-ghost"

    buildspec = templatefile("templates/gatsby.yml.tpl", {
      artifacts_bucket = aws_s3_bucket.ggjam-website.bucket
      ghost_api_key = var.ghost_api_key
      ghost_url = "${aws_service_discovery_service.ghost.name}.${aws_service_discovery_private_dns_namespace.ggjam.name}"
      ghost_port = var.ghost_port 
    })
  }

  vpc_config {
    vpc_id = aws_vpc.ggjam.id

    subnets = [
      aws_subnet.private-a.id,
      aws_subnet.private-b.id
    ]

    security_group_ids = [
      aws_security_group.gatsby.id
    ]
  }
}

resource "aws_codebuild_webhook" "ggjam_build" {
  project_name = aws_codebuild_project.ggjam_frontend.name
  filter_group {
    filter {
      type = "EVENT"
      pattern = "PUSH" 
    }
  }
}

output "webhook-endpoint" {
  value = aws_codebuild_webhook.ggjam_build.payload_url
}