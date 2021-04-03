output "S3_Website" {
  value = aws_s3_bucket.ggjam-website.website_endpoint
}

output "content-location" {
  value = aws_s3_bucket.ggjam-content.website_endpoint
}

output "content-bucket-name" {
  value = aws_s3_bucket.ggjam-content.bucket
}
