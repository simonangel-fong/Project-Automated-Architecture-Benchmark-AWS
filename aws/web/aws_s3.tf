# ########################################
# S3 App bucket
# ########################################

locals {
  bucket_id     = "${var.project}-bucket"
  web_file_path = "../../app/html"
}

resource "aws_s3_bucket" "web" {
  bucket        = local.bucket_id
  force_destroy = true
  tags = {
    Name = local.bucket_id
  }
}

# Enabe bucket versioning
resource "aws_s3_bucket_versioning" "web" {
  bucket = aws_s3_bucket.web.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ########################################
# Upload web files
# ########################################

module "web_file" {
  source = "hashicorp/dir/template"

  base_dir = local.web_file_path
}

# update S3 object resource for hosting bucket files
resource "aws_s3_object" "web_file" {
  bucket = aws_s3_bucket.web.id

  # loop all files
  for_each     = module.web_file.files
  key          = each.key
  content_type = each.value.content_type

  source  = each.value.source_path
  content = each.value.content

  # ETag of the S3 object
  etag = each.value.digests.md5
}

# ########################################
# Enable static website hosting
# ########################################
resource "aws_s3_bucket_website_configuration" "web" {
  bucket = aws_s3_bucket.web.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# ########################################
# Permission
# ########################################

# Enable bucket public access block
resource "aws_s3_bucket_public_access_block" "bucket_public_access" {
  bucket = aws_s3_bucket.web.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

# set ownership
resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
  bucket = aws_s3_bucket.web.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# set access control list
resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.web.id
  acl    = "public-read"

  depends_on = [
    aws_s3_bucket_ownership_controls.bucket_ownership,
    aws_s3_bucket_public_access_block.bucket_public_access
  ]
}

# Enable bucket policy for public read access
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.web.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.web.id}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.bucket_public_access]
}
