
locals {
	tags = {
		purpose = "CDN"
		env     = local.environment
	}

	cdns = [
		{
			name    = "stoogoff"
			zone_id = var.zone_id_stoogoff
			domain  = "cdn.stoogoff.com"
			target_origin = "${local.environment}-cdn-stoogoff"
		},
		{
			name    = "aegean"
			zone_id = var.zone_id_aegean
			domain  = "cdn.aegeanrpg.com"
			target_origin = "${local.environment}-cdn-aegeanrpg"
		}
	]
}

resource "aws_s3_bucket" "cdn_bucket" {
	count = length(local.cdns)

	bucket = local.cdns[count.index].domain
	acl    = "private"

	versioning {
		enabled = false
	}

	tags = local.tags
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
	count = length(local.cdns)
	comment = "cdn-${local.cdns[count.index].name}-${local.environment}-access"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
	count = length(local.cdns)

	origin {
		domain_name = aws_s3_bucket.cdn_bucket[count.index].bucket_regional_domain_name
		origin_id   = local.cdns[count.index].target_origin

		s3_origin_config {
			origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity[count.index].cloudfront_access_identity_path
		}
	}

	enabled             = true
	is_ipv6_enabled     = true
	comment             = local.cdns[count.index].name
	default_root_object = "index.html"
	aliases             = [local.cdns[count.index].domain]

	default_cache_behavior {
		allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
		cached_methods   = ["GET", "HEAD"]
		target_origin_id = local.cdns[count.index].target_origin

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
	count = length(aws_s3_bucket.cdn_bucket)

	statement {
		actions   = ["s3:GetObject"]
		resources = ["${aws_s3_bucket.cdn_bucket[count.index].arn}/*"]

		principals {
			type        = "AWS"
			identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity[count.index].iam_arn]
		}
	}
}

resource "aws_s3_bucket_policy" "cdn_bucket" {
	count = length(aws_s3_bucket.cdn_bucket)

	bucket = aws_s3_bucket.cdn_bucket[count.index].id
	policy = data.aws_iam_policy_document.s3_policy[count.index].json
}

resource "aws_s3_bucket_public_access_block" "cdn_bucket" {
	count = length(aws_s3_bucket.cdn_bucket)

	bucket = aws_s3_bucket.cdn_bucket[count.index].id

	block_public_acls   = true
	block_public_policy = true
}

resource "aws_route53_record" "cdn" {
	count = length(local.cdns)

	zone_id = local.cdns[count.index].zone_id
	name    = local.cdns[count.index].domain
	type    = "CNAME"
	ttl     = 300
	records = [aws_cloudfront_distribution.s3_distribution[count.index].domain_name]
}