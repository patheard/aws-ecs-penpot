module "penpot_asset_bucket" {
  source            = "github.com/cds-snc/terraform-modules//S3?ref=v10.2.1"
  bucket_name       = "cds-penpot-assets-${var.env}"
  billing_tag_value = var.billing_code

  versioning = {
    enabled = true
  }
}