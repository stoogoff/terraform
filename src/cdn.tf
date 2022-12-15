

locals {
	tags = {
		purpose = "CDN"
		env     = local.environment
	}
	target_origin = "${local.environment}-cdn-stoogoff"
}

resource "aws_s3_bucket" "cdn_bucket" {
	bucket = var.cdn_bucket_name
	acl    = "private"

	versioning {
		enabled = false
	}

	tags = local.tags
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
	comment = "cdn-${local.environment}-access"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
	origin {
		domain_name = aws_s3_bucket.cdn_bucket.bucket_regional_domain_name
		origin_id   = local.target_origin

		s3_origin_config {
			origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
		}
	}

	enabled             = true
	is_ipv6_enabled     = true
	comment             = "CDN Distribution"
	default_root_object = "index.html"
	aliases             = ["cdn.stoogoff.com"]

	default_cache_behavior {
		allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
		cached_methods   = ["GET", "HEAD"]
		target_origin_id = local.target_origin

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

	price_class = "PriceClass_200"

	restrictions {
		geo_restriction {
			restriction_type = "none"
		}
	}

	tags = local.tags

	viewer_certificate {
		acm_certificate_arn = var.certificate_useast1
		ssl_support_method  = "sni-only"
	}
}

data "aws_iam_policy_document" "s3_policy" {
	statement {
		actions   = ["s3:GetObject"]
		resources = ["${aws_s3_bucket.cdn_bucket.arn}/*"]

		principals {
			type        = "AWS"
			identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
		}
	}
}

resource "aws_s3_bucket_policy" "cdn_bucket" {
	bucket = aws_s3_bucket.cdn_bucket.id
	policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_s3_bucket_public_access_block" "cdn_bucket" {
	bucket = aws_s3_bucket.cdn_bucket.id

	block_public_acls   = true
	block_public_policy = true
}

resource "aws_route53_record" "cdn" {
	zone_id = var.zone_id
	name    = "cdn.stoogoff.com"
	type    = "CNAME"
	ttl     = 300
	records = [aws_cloudfront_distribution.s3_distribution.domain_name]
}