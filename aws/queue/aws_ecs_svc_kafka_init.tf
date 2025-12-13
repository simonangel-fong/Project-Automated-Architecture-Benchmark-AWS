# locals {
#   topic_init_run_command = <<EOF
# aws ecs run-task
#   --cluster ${aws_ecs_cluster.ecs_cluster.name}
#   --launch-type FARGATE 
#   --task-definition ${aws_ecs_task_definition.topic_init.family} 
#   --network-configuration "awsvpcConfiguration={subnets=[${join(",", [for s in aws_subnet.public : s.id])}],securityGroups=[${aws_security_group.producer.id}],assignPublicIp=ENABLED}"
# EOF
# }



# # ##############################
# # IAM: ECS Task execution role
# # ##############################
# # assume policy
# data "aws_iam_policy_document" "assume_role_msk_init" {
#   statement {
#     effect = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["ecs-tasks.amazonaws.com"]
#     }
#     actions = ["sts:AssumeRole"]
#   }
# }




# data "aws_iam_policy_document" "msk_init" {
#   statement {
#     sid    = "ClusterConnectDescribe"
#     effect = "Allow"
#     actions = [
#       "kafka-cluster:Connect",
#       "kafka-cluster:DescribeCluster",
#       "kafka-cluster:DescribeClusterDynamicConfiguration",
#     ]
#     resources = [
#       "arn:aws:kafka:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${aws_msk_cluster.kafka.cluster_name}/*"
#     ]
#   }

#   statement {
#     sid    = "CreateTelemetryTopic"
#     effect = "Allow"
#     actions = [
#       "kafka-cluster:CreateTopic",
#       "kafka-cluster:DescribeTopic",
#       "kafka-cluster:DescribeTopicDynamicConfiguration",
#       "kafka-cluster:AlterTopic",
#       "kafka-cluster:AlterTopicDynamicConfiguration",
#       "kafka-cluster:WriteData",
#     ]
#     resources = [
#       "arn:aws:kafka:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topic/${aws_msk_cluster.kafka.cluster_name}/*/telemetry"
#     ]
#   }
# }

# resource "aws_iam_policy" "msk_init" {
#   name   = "${var.project}-${var.env}-topic-init-msk"
#   policy = data.aws_iam_policy_document.msk_init.json
# }

# resource "aws_iam_role_policy_attachment" "msk_init" {
#   role       = aws_iam_role.ecs_task_role_producer.name
#   policy_arn = aws_iam_policy.topic_init_msk.arn
# }


# resource "aws_ecs_task_definition" "topic_init" {
#   family                   = "${var.project}-${var.env}-topic-init"
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   cpu                      = 256
#   memory                   = 512

#   execution_role_arn = aws_iam_role.ecs_task_execution_role_producer.arn
#   task_role_arn      = aws_iam_role.ecs_task_role_producer.arn

#   container_definitions = jsonencode([
#     {
#       name      = "topic-init"
#       image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project}:kafka-init"
#       essential = true

#       environment = [
#         { name = "BOOTSTRAP_SERVERS", value = aws_msk_cluster.kafka.bootstrap_brokers_sasl_iam },
#         { name = "TOPIC_NAME", value = "telemetry" },
#         { name = "PARTITIONS", value = "3" },
#         { name = "REPLICATION_FACTOR", value = "3" }
#       ]

#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           awslogs-group         = "/ecs/task/${var.project}-${var.env}-topic-init"
#           awslogs-region        = var.aws_region
#           awslogs-stream-prefix = "ecs"
#         }
#       }
#     }
#   ])
# }

# resource "aws_cloudwatch_log_group" "topic_init" {
#   name              = "/ecs/task/${var.project}-${var.env}-topic-init"
#   retention_in_days = 7
#   kms_key_id        = aws_kms_key.cloudwatch_log.arn
# }

# output "run_topic_init_task" {
#   description = "Run this command ONCE to create Kafka topics"
#   value       = <<EOF

# aws ecs run-task
#   --cluster ${aws_ecs_cluster.ecs_cluster.name}
#   --launch-type FARGATE 
#   --task-definition ${aws_ecs_task_definition.topic_init.family} 
#   --network-configuration "awsvpcConfiguration={subnets=[${join(",", [for s in aws_subnet.public : s.id])}],securityGroups=[${aws_security_group.producer.id}],assignPublicIp=ENABLED}"

# EOF
# }
