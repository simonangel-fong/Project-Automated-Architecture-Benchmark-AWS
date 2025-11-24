# aws_vpc.tf

# # ##############################
# # VPC flow logs
# # ##############################
# resource "aws_flow_log" "this" {
#   count = try(local.vpc.flow_log_s3_bucket_name != null, false) ? 1 : 0

#   log_destination      = "${data.aws_s3_bucket.this[0].arn}/${data.aws_vpc.this.id}/"
#   log_destination_type = "s3"
#   traffic_type         = "ALL"
#   vpc_id               = data.aws_vpc.this.id
# }

# ##############################
# VPC
# ##############################
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-${var.env}-vpc"
  }
}
