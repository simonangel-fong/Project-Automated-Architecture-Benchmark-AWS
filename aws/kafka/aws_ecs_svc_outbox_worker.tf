# aws_ecs_svc_outbox_worker.tf

# #################################
# Variable
# #################################
locals {
  outbox_worker_log_id           = "/ecs/task/${var.project}-${var.env}-outbox-worker"
  outbox_worker_ecr              = "${local.ecr_repo}:${var.svc_param.outbox_worker_svc.image_suffix}"
  outbox_worker_log_level        = "WARNING"
  outbox_worker_cpu              = var.svc_param.outbox_worker_svc.cpu
  outbox_worker_memory           = var.svc_param.outbox_worker_svc.memory
  outbox_worker_desired          = var.svc_param.outbox_worker_svc.count_desired
  outbox_worker_min              = var.svc_param.outbox_worker_svc.count_min
  outbox_worker_max              = var.svc_param.outbox_worker_svc.count_max
  outbox_worker_env_pool_size    = var.svc_param.outbox_worker_svc.container_env["pool_size"]
  outbox_worker_env_max_overflow = var.svc_param.outbox_worker_svc.container_env["max_overflow"]
  outbox_worker_env_pgdb_host    = aws_db_instance.postgres.address
  outbox_worker_env_pgdb_db      = aws_db_instance.postgres.db_name
  outbox_worker_env_pgdb_user    = aws_db_instance.postgres.username
  outbox_worker_env_pgdb_pwd     = aws_db_instance.postgres.password
  outbox_worker_scale_cpu        = var.threshold_cpu
}

# #################################
# IAM: Execution Role
# #################################
# assume role
resource "aws_iam_role" "execution_role_outbox" {
  name               = "${var.project}-${var.env}-execution-role-outbox"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ecs.json

  tags = {
    Project = var.project
    Role    = "ecs-task-execution-role-outbox"
  }
}

# policy attachment: exec role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_outbox" {
  role       = aws_iam_role.execution_role_outbox.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# #################################
# IAM: Task Role
# #################################
resource "aws_iam_role" "outbox_task_role" {
  name               = "${var.project}-${var.env}-task-role-outbox"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ecs.json
}

# ##############################
# Security Group
# ##############################
resource "aws_security_group" "outbox_worker" {
  name        = "${var.project}-${var.env}-sg-outbox-worker"
  description = "Outbox worker security group"
  vpc_id      = aws_vpc.main.id

  # no ingress needed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.env}-sg-outbox-worker"
  }
}

# #################################
# CloudWatch: log group
# #################################
resource "aws_cloudwatch_log_group" "log_group_outbox" {
  name              = local.outbox_worker_log_id
  retention_in_days = 7
  kms_key_id        = aws_kms_key.cloudwatch_log.arn

  tags = {
    Name = local.outbox_worker_log_id
  }
}

# #################################
# ECS: Task Definition
# #################################
resource "aws_ecs_task_definition" "ecs_task_outbox_worker" {
  family                   = "${var.project}-${var.env}-task-outbox_worker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = local.outbox_worker_cpu
  memory                   = local.outbox_worker_memory

  execution_role_arn = aws_iam_role.execution_role_outbox.arn
  task_role_arn      = aws_iam_role.outbox_task_role.arn

  container_definitions = templatefile("${path.module}/container/outbox_worker.tftpl", {
    project       = var.project
    region        = var.aws_region
    env           = var.env
    debug         = var.debug
    log_level     = local.outbox_worker_log_level
    awslogs_group = local.outbox_worker_log_id
    image         = local.outbox_worker_ecr
    cpu           = local.outbox_worker_cpu
    memory        = local.outbox_worker_memory
    pool_size     = local.outbox_worker_env_pool_size
    max_overflow  = local.outbox_worker_env_max_overflow
    worker        = local.fastapi_env_worker
    pgdb_host     = local.outbox_worker_env_pgdb_host
    pgdb_db       = local.outbox_worker_env_pgdb_db
    pgdb_user     = local.outbox_worker_env_pgdb_user
    pgdb_pwd      = local.outbox_worker_env_pgdb_pwd
    redis_host    = aws_elasticache_replication_group.redis.primary_endpoint_address
    redis_port    = aws_elasticache_replication_group.redis.port
  })

  tags = {
    Name = "${var.project}-${var.env}-task-outbox-worker"
  }
}

# #################################
# ECS: Service
# #################################
resource "aws_ecs_service" "ecs_svc_outbox_worker" {
  name    = "${var.project}-${var.env}-service-outbox-worker"
  cluster = aws_ecs_cluster.ecs_cluster.id

  task_definition  = aws_ecs_task_definition.ecs_task_outbox_worker.arn
  desired_count    = local.outbox_worker_desired
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    security_groups  = [aws_security_group.outbox_worker.id]
    subnets          = [for subnet in aws_subnet.private : subnet.id]
    assign_public_ip = false
  }

  tags = {
    Name = "${var.project}-${var.env}-service-outbox-worker"
  }

  depends_on = [
    aws_cloudwatch_log_group.log_group_outbox,
  ]
}
