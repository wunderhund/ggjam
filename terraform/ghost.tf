resource "aws_s3_bucket" "ggjam-content" {
  bucket        = var.content_s3_bucket
  acl           = "public-read"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

data "aws_iam_policy_document" "ggjam-content-bucket-policy" {
  statement {
    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.ggjam-content.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "ggjam-content-bucket-policy" {
  bucket = aws_s3_bucket.ggjam-content.id
  policy = data.aws_iam_policy_document.ggjam-content-bucket-policy.json
}

resource "aws_iam_user" "ggjam-content" {
  name = "ggjam-content"
  path = "/system/"
}

resource "aws_iam_access_key" "ggjam-content" {
  user = aws_iam_user.ggjam-content.name
}

data "aws_iam_policy_document" "ggjam-content" {
  statement {
    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.ggjam-content.arn
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:PutObjectVersionAcl",
      "s3:DeleteObject",
      "s3:PutObjectAcl"
    ]

    resources = [
      "${aws_s3_bucket.ggjam-content.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "ggjam-content" {
  name        = "ggjam-content"
  description = "Ghost Content Storage Policy"
  path        = "/service-role/"
  policy      = data.aws_iam_policy_document.ggjam-content.json
}

resource "aws_iam_policy_attachment" "ggjam-content" {
  name       = "ggjam-content"
  users      = [aws_iam_user.ggjam-content.name]
  policy_arn = aws_iam_policy.ggjam-content.arn
}
