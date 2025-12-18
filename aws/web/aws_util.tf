data "aws_region" "current" {}

# acm certificate
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "aws_acm_certificate" "cf_certificate" {
  domain      = "*.${var.domain_name}"
  provider    = aws.us_east_1
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}
