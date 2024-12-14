module "penpot_asset_bucket" {
  source            = "github.com/cds-snc/terraform-modules//S3?ref=v10.2.1"
  bucket_name       = "cds-penpot-assets-${var.env}"
  billing_tag_value = var.billing_code

  versioning = {
    enabled = true
  }
}

resource "aws_s3_bucket_website_configuration" "penpot_assets" {
  bucket = module.penpot_asset_bucket.s3_bucket_id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_cors_configuration" "penpot_assets" {
  bucket = module.penpot_asset_bucket.s3_bucket_id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = [var.domain]
    max_age_seconds = 3000
  }
}