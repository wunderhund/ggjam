resource "aws_security_group" "ghost" {
  name        = "ghost"
  description = "Security Group for Ghost containers"
  vpc_id      = aws_vpc.ggjam.id

  ingress {
    description     = "SSH Access to Ghost container"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jumpbox.id]
  }

  ingress {
    description     = "HTTP access to Ghost container"
    from_port       = var.ghost_port
    to_port         = var.ghost_port
    protocol        = "tcp"
    security_groups = [aws_security_group.gatsby.id, aws_security_group.jumpbox.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "ghost"
    },
    var.base_tags
  )
}

resource "aws_ecs_cluster" "ghost" {
  name               = "ghost"
  capacity_providers = ["FARGATE"]

  tags = merge(
    {
      Name = "ghost"
    },
    var.base_tags
  )
}

resource "aws_iam_role" "ghost" {
  name               = "ghost"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
              "Service": "ecs-tasks.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ghost" {
  role       = aws_iam_role.ghost.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "ghost_cloudwatch" {
  name = "/ecs/ggjam-ghost"
}

resource "aws_ecs_task_definition" "ghost" {
  family                   = "ghost"
  task_role_arn            = aws_iam_role.ghost.arn
  execution_role_arn       = aws_iam_role.ghost.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory                   = "2048"
  cpu                      = "1024"
  container_definitions = templatefile("templates/ghost.json.tpl", {
    host      = aws_db_instance.ghost.address
    port      = var.ghost_port
    user      = var.ghostdb_user
    pass      = var.ghostdb_pass
    log_group = aws_cloudwatch_log_group.ghost_cloudwatch.name
    region    = data.aws_region.current.name
  })
}

resource "aws_ecs_service" "ghost" {
  name            = "ghost"
  cluster         = aws_ecs_cluster.ghost.id
  task_definition = aws_ecs_task_definition.ghost.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = [aws_subnet.private-a.id, aws_subnet.private-b.id]
    security_groups = [aws_security_group.ghost.id]
  }
  deployment_controller {
    type = "ECS"
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.ghost.arn
    container_name = "ghost"
  }

}

resource "aws_service_discovery_private_dns_namespace" "ggjam" {
  name        = "ggjam.test"
  description = "ggjam dns namespace"
  vpc         = aws_vpc.ggjam.id
}


resource "aws_service_discovery_service" "ghost" {
  name = "ghost"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ggjam.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

#output "ghost-ip" {
#    value = aws_instance.jumpbox.private_ip
#}

