locals { mime_types = jsondecode(file("./templates/mime.json")) }

# S3 BUCKET WEBSITE
resource "aws_s3_bucket" "translator_bucket" {
  bucket = "cloud-translator.com2"
  tags = {
    Name        = "S3 Website"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.translator_bucket.id
  policy = templatefile("./templates/bucket_policy.json", { aws_principal = "${aws_cloudfront_origin_access_identity.CFOAI.iam_arn}", action = "s3:GetObject", resource_arn = "${aws_s3_bucket.translator_bucket.arn}/*" })
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.translator_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "translator_website_bucket_acl" {
  bucket = aws_s3_bucket.translator_bucket.id
  acl    = "public-read"
  depends_on = [aws_s3_bucket_public_access_block.translateAccessBlock, aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
}

resource "aws_s3_bucket_public_access_block" "translateAccessBlock" {
  bucket = aws_s3_bucket.translator_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  restrict_public_buckets = false
  ignore_public_acls      = false
}

resource "aws_s3_bucket_website_configuration" "translator_website_bucket_bucketWebConfig" {
  bucket = aws_s3_bucket.translator_bucket.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_cors_configuration" "translator_website_bucket_bucketCORS" {
  bucket = aws_s3_bucket.translator_bucket.id

  cors_rule {
    allowed_headers = ["Authorization", "Content-Length"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://cloud-translator.com"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_object" "website_files" {
  for_each     = fileset("./website/", "**")
  bucket       = aws_s3_bucket.translator_bucket.id
  key          = each.value
  source       = "./website/${each.value}"
  etag         = filemd5("./website/${each.value}")
  content_type = lookup(local.mime_types, regex("\\.[^.]+$", each.value), null)
}

# CLOUDFRONT
resource "aws_cloudfront_origin_access_identity" "CFOAI" {
  comment = "S3 OAI"
}

resource "aws_cloudfront_distribution" "translator_s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.translator_bucket.bucket_domain_name
    origin_id   = aws_s3_bucket.translator_bucket.id

#    origin_shield {
#      enabled              = false
#      origin_shield_region = "us-east-1"
#    }

#    s3_origin_config {
#      origin_access_identity = aws_cloudfront_origin_access_identity.CFOAI.cloudfront_access_identity_path
#    }
  }
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }
  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.translator_bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:483451515855:certificate/3e600b89-cbda-40a2-8ef0-5e3aacc0159c"  //it should exists in the ACM of your AWS Account in the CloudFront section
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name        = "Cloudfront CDN"
    Environment = "Production"
  }
}

#Route53 resources
resource "aws_route53_zone" "translator-route53-zone" {
  name = "cloud-translator.com2"
}

resource "aws_route53_record" "translator-cloudfront-translator-ipv4" {
  zone_id = aws_route53_zone.translator-route53-zone.id
  name    = "cloud-translator.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.translator_s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.translator_s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_health_check" "r53HealthCheck" {
  fqdn              = "cloud-translator.com"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"

  tags = {
    Name        = "HTTP Health Check"
    Environment = "Production"
  }
}
