resource "aws_ecs_cluster" "ecs-cluster" {
  name = "ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Environment = "Production"
    Name        = "ECS Cluster"
  }
}

resource "aws_ecs_service" "translate-service" {
  name            = "translate-service"
  cluster         = aws_ecs_cluster.ecs-cluster.id
  task_definition = aws_ecs_task_definition.ecs-task-definition-medium.arn
  desired_count   = 2
  depends_on      = [aws_iam_role_policy_attachment.ecs-task-role-policy-attachment1]
  health_check_grace_period_seconds = 2147483647
  launch_type = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.translator_ecs_security_group.id]
    subnets         = [aws_subnet.private_backend_vpc_subnet1.id, aws_subnet.private_backend_vpc_subnet2.id]
  }

   load_balancer {
    target_group_arn = aws_lb_target_group.translator_ecs_target_group.arn
    container_name   = "translator_container"
    container_port   = 8081
  }
}

/*resource "aws_ecr_repository" "translator-ecr" {
  name                 = "translator-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}*/

output "ecs-repo" {
  value       = "483451515855.dkr.ecr.us-west-1.amazonaws.com/translator2-repo"
  description = "ECR Repository Name"
}

/* Role for ECS task definition */
resource "aws_iam_role" "ecs-task-exec" {
  name        = "ecs-task-execution-role-v2"
  description = "Allows the execution of ECS tasks"

  assume_role_policy = templatefile("./templates/ECSRole.json", {})
}

resource "aws_iam_role_policy_attachment" "ecs-task-exec-policy-attachment" {
  role       = aws_iam_role.ecs-task-exec.id

  # Attach the first additional policy
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs-task-exec-cloudwatch-policy-attachment" {
  role       = aws_iam_role.ecs-task-exec.id

  # Attach the first additional policy
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_policy" "ecr-policy" {
  name        = "ECRPolicy"
  description = ""

  policy = templatefile("./templates/ECRPermissions.json", {})
}

resource "aws_iam_role_policy_attachment" "ecs-task-role-policy-attachment1" {
  role       = aws_iam_role.ecs-task-exec.id
  policy_arn = aws_iam_policy.ecr-policy.arn
}

resource "aws_iam_role" "ecs-resources-access" {
  name        = "ecs-resources-access"
  description = "Allows ECS tasks to call AWS services on your behalf"

  assume_role_policy = templatefile("./templates/ECSRole.json", {})
}

resource "aws_iam_role_policy_attachment" "ecs-cli-policy-attachment" {
  role       = aws_iam_role.ecs-resources-access.id

  # Attach the first additional policy
  policy_arn = "arn:aws:iam::483451515855:policy/ECS-for-CLI-Exec"
}

resource "aws_iam_role_policy_attachment" "ecs-resources-full-access-policy-attachment" {
  role       = aws_iam_role.ecs-resources-access.id

  # Attach the first additional policy
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

/* Definition ecs task with different sizes for different workloads */

/* Medium*/
resource "aws_ecs_task_definition" "ecs-task-definition-medium" {
  family                = "translator-medium"
  container_definitions = templatefile("./templates/ContainerConf.json", { name = "translator_container", repo = "483451515855.dkr.ecr.us-west-1.amazonaws.com/translator2-repo:latest", logGroup = "${aws_cloudwatch_log_group.ECSLogGroup.name}" })

  task_role_arn      = aws_iam_role.ecs-resources-access.arn
  execution_role_arn = aws_iam_role.ecs-task-exec.arn

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  tags = {
    Environment = "Production"
    Name        = "Task Definition MEDIUM"
  }
}

resource "aws_ecs_task_set" "translator-task-set" {
  service         = aws_ecs_service.translate-service.id
  cluster         = aws_ecs_cluster.ecs-cluster.id
  task_definition = aws_ecs_task_definition.ecs-task-definition-medium.arn
  launch_type     = "FARGATE"
  /* wait_until_stable = true # is this necessary? it could solve the empty output problem but no guarantees are given*/

  /* load_balancer {
    target_group_arn = aws_lb_target_group.example.arn
    container_name   = "mongo"
    container_port   = 8080
  } */
}

resource "aws_cloudwatch_log_group" "ECSLogGroup" {
  name              = "/aws/ecs/translator_container"
  retention_in_days = 90

  tags = {
    Application = "ECS Cluster"
    Environment = "Production"
  }
}

