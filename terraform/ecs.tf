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
  iam_role        = aws_iam_role.ecs-task-exec.arn
  depends_on      = [aws_iam_role_policy_attachment.ecs-task-role-policy-attachment1]
  #health_check_grace_period_seconds = 2147483647
  launch_type = "FARGATE"

  /* load_balancer {
    target_group_arn = "${aws_lb_target_group.foo.arn}"
    container_name   = "mongo"
    container_port   = 8080
  } */
}

resource "aws_ecr_repository" "translator-ecr" {
  name                 = "translator-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

output "ecs-repo" {
  value       = aws_ecr_repository.translator-ecr.name
  description = "ECR Repository Name"
}

/* Role for ECS task definition */
resource "aws_iam_role" "ecs-task-exec" {
  name        = "ecs-task-execution-role-v2"
  description = "Allows the execution of ECS tasks"

  assume_role_policy = templatefile("./templates/ECSRole.json", {})
}

resource "aws_iam_policy" "ecr-policy" {
  name        = "ECRPolicy"
  description = ""

  policy = templatefile("./templates/ECRPermissions.json", {})
}

resource "aws_iam_role_policy_attachment" "ecs-task-role-policy-attachment1" {
  role       = aws_iam_role.ecs-task-exec.name
  policy_arn = aws_iam_policy.ecr-policy.arn
}

resource "aws_iam_role" "ecs-resources-access" {
  name        = "ecs-resources-access"
  description = "Allows ECS tasks to call AWS services on your behalf"

  assume_role_policy = templatefile("./templates/ECSRole.json", {})
}

resource "aws_iam_role_policy_attachment" "ecs-resources-access-role-policy-attachment1" {
  role       = aws_iam_role.ecs-resources-access.name
  policy_arn = aws_iam_policy.ecr-policy.arn
}

/* Definition ecs task with different sizes for different workloads */
/* Small */
resource "aws_ecs_task_definition" "ecs-task-definition-small" {
  family                = "translator-small"
  container_definitions = templatefile("./templates/ContainerConf.json", { name = "${aws_ecr_repository.translator-ecr.name}", repo = "${aws_ecr_repository.translator-ecr.repository_url}", logGroup = "${aws_cloudwatch_log_group.ECSLogGroup.name}" })

  task_role_arn      = aws_iam_role.ecs-resources-access.arn
  execution_role_arn = aws_iam_role.ecs-task-exec.arn

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = {
    Environment = "Production"
    Name        = "Task Definition SMALL"
  }
}

/* Medium*/
resource "aws_ecs_task_definition" "ecs-task-definition-medium" {
  family                = "translator-medium"
  container_definitions = templatefile("./templates/ContainerConf.json", { name = "${aws_ecr_repository.translator-ecr.name}", repo = "${aws_ecr_repository.translator-ecr.repository_url}", logGroup = "${aws_cloudwatch_log_group.ECSLogGroup.name}" })

  task_role_arn      = aws_iam_role.ecs-resources-access.arn
  execution_role_arn = aws_iam_role.ecs-task-exec.arn

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = {
    Environment = "Production"
    Name        = "Task Definition MEDIUM"
  }
}

/*Large*/
resource "aws_ecs_task_definition" "ecs-task-definition-large" {
  family                = "translator-large"
  container_definitions = templatefile("./templates/ContainerConf.json", { name = "${aws_ecr_repository.translator-ecr.name}", repo = "${aws_ecr_repository.translator-ecr.repository_url}", logGroup = "${aws_cloudwatch_log_group.ECSLogGroup.name}" })

  task_role_arn      = aws_iam_role.ecs-resources-access.arn
  execution_role_arn = aws_iam_role.ecs-task-exec.arn

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = {
    Environment = "Production"
    Name        = "Task Definition LARGE"
  }
}

resource "aws_ecs_task_set" "translator-task-set" {
  service         = aws_ecs_service.translate-service.id
  cluster         = aws_ecs_cluster.ecs-cluster.id
  task_definition = aws_ecs_task_definition.ecs-task-definition-medium.arn
  launch_type     = "FARGATE"


  /* load_balancer {
    target_group_arn = aws_lb_target_group.example.arn
    container_name   = "mongo"
    container_port   = 8080
  } */
}

resource "aws_cloudwatch_log_group" "ECSLogGroup" {
  name              = "/aws/ecs/${aws_ecr_repository.translator-ecr.name}"
  retention_in_days = 90

  tags = {
    Application = "ECS Cluster"
    Environment = "Production"
  }
}

