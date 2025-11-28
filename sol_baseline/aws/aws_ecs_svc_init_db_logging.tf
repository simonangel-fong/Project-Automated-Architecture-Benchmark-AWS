resource "aws_cloudwatch_log_group" "db_init" {
  name              = "/ecs/task/${var.project}-${var.env}-db-init"
  retention_in_days = 7

  kms_key_id = aws_kms_key.cloudwatch_log.arn

  tags = {
    Name = "${var.project}-${var.env}-log-group-db-init"
  }
}
