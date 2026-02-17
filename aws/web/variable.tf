# ##############################
# APP
# ##############################
variable "project" {
  type    = string
  default = "automated-architecture-benchmark"
}

variable "env" {
  type    = string
  default = "dev"
}

# ##############################
# AWS
# ##############################
variable "aws_region" { type = string }

# ##############################
# Cloudflare
# ##############################
variable "cloudflare_api_token" { type = string }
variable "cloudflare_zone_id" { type = string }

# ##############################
# AWS Cloudfront
# ##############################
variable "domain_name" { type = string }

locals {
  dns_record = var.env == "prod" ? "benchmark.${var.domain_name}" : "benchmark-${var.env}.${var.domain_name}"
}