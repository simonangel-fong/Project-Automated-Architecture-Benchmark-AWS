locals {
  ecr_db_init = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project}-db-init:${var.env}"
}

# #################################
# ECS: Task Definition
# #################################
resource "aws_ecs_task_definition" "db_init" {
  family                   = "${var.project}-${var.env}-task-db-init"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  execution_role_arn = aws_iam_role.ecs_task_execution_role_fastapi.arn
  task_role_arn      = aws_iam_role.ecs_task_execution_role_fastapi.arn

  container_definitions = jsonencode([
    {
      name      = "db-init"
      image     = local.ecr_db_init
      essential = true

      command = [
        "sh", "-c",
        "psql \"postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.postgres.address}:5432/${var.db_name}\" -f /sql/01_schema.sql -f /sql/02_seed.sql"
      ]

      environment = [
        { name = "DB_HOST", value = aws_db_instance.postgres.address },
        { name = "DB_NAME", value = var.db_name },
        { name = "DB_USER", value = var.db_username },
        { name = "DB_PASSWORD", value = var.db_password }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.db_init.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "db-init"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project}-${var.env}-task-db-init"
  }

  depends_on = [
    aws_db_instance.postgres,
    aws_cloudwatch_log_group.db_init,
  ]
}
