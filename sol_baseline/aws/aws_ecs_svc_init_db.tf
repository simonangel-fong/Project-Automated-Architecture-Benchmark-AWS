locals {
  ecr_init_db = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project}-init-db:${var.env}"
}

# #################################
# IAM: ECS Task Execution Role
# #################################
# assume role
resource "aws_iam_role" "ecs_task_execution_role_init_db" {
  name               = "${var.project}-${var.env}-task-execution-role-init-db"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ecs.json

  tags = {
    Project = var.project
    Role    = "ecs-task-execution-role-init-db"
  }
}

# policy attachment: exec role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_init_db" {
  role       = aws_iam_role.ecs_task_execution_role_init_db.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# #################################
# IAM: ECS Task Role
# #################################
resource "aws_iam_role" "ecs_task_role_init_db" {
  name               = "${var.project}-${var.env}-task-role-init-db"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ecs.json
}

# ##############################
# Security Group
# ##############################
resource "aws_security_group" "init_db" {
  name        = "${var.project}-${var.env}-sg-init-db"
  description = "Security group init_db"
  vpc_id      = aws_vpc.main.id

  # Egress to vpc only
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = [aws_vpc.main.cidr_block]
  }


  tags = {
    Name = "${var.project}-${var.env}-sg-init-db"
  }
}

# #################################
# ECS: Task Definition
# #################################
resource "aws_ecs_task_definition" "init_db" {
  family                   = "init-db"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role_init_db.arn
  task_role_arn            = aws_iam_role.ecs_task_role_init_db.arn

  container_definitions = templatefile("${path.module}/container/init_db.tftpl", {
    image         = local.ecr_init_db
    awslogs_group = aws_cloudwatch_log_group.init_db.name
    region        = var.aws_region

    pghost     = aws_db_instance.postgres.address
    pgport     = 5432
    pgdatabase = aws_db_instance.postgres.db_name
    pguser     = aws_db_instance.postgres.username
    pgpwd      = aws_db_instance.postgres.password
  })

  tags = {
    Name = "${var.project}-${var.env}-task-db-init"
  }

  depends_on = [
    aws_db_instance.postgres,
    aws_cloudwatch_log_group.init_db,
  ]
}


# #################################
# ECS: Service
# #################################
resource "aws_ecs_service" "ecs_svc_init_db" {
  name    = "${var.project}-${var.env}-service-init-db"
  cluster = aws_ecs_cluster.ecs_cluster.id

  # task
  task_definition  = aws_ecs_task_definition.init_db.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  # network
  network_configuration {
    subnets          = [for subnet in aws_subnet.private : subnet.id]
    security_groups  = [aws_security_group.init_db.id]
    assign_public_ip = false # disable public ip
  }

  tags = {
    Name = "${var.project}-${var.env}-service-init-db"
  }

  depends_on = [
    aws_cloudwatch_log_group.init_db,
    aws_vpc_endpoint.ecr_api,
    aws_vpc_endpoint.ecr_dkr,
    aws_vpc_endpoint.s3,
  ]
}
