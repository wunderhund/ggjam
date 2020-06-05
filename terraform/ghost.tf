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

data "aws_iam_policy_document" "ghost-api-invoke" {
  statement {
    actions = [
      "execute-api:Invoke"
    ]

    resources = [
      "arn:aws:execute-api:us-west-2:925412914118:9xygkt8j2a/*"
    ]
  }
}

resource "aws_iam_policy" "ghost-api-invoke" {
  name        = "ghost-api-invoke"
  description = "Ghost Webhook Invocation Policy"
  path        = "/service-role/"
  policy      = data.aws_iam_policy_document.ghost-api-invoke.json
}

resource "aws_iam_role_policy_attachment" "ghost-api-invoke" {
  role       = aws_iam_role.ghost.name
  policy_arn = aws_iam_policy.ghost-api-invoke.arn
}

resource "aws_iam_role_policy_attachment" "ghost" {
  role       = aws_iam_role.ghost.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "ghost_cloudwatch" {
  name = "/ecs/ggjam-ghost"
}

resource "aws_s3_bucket" "ggjam-content" {
  bucket        = var.content_s3_bucket
  acl           = "public-read"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

data "aws_iam_policy_document" "ggjam-content-bucket-policy" {
  statement {
    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.ggjam-content.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "ggjam-content-bucket-policy" {
  bucket = aws_s3_bucket.ggjam-content.id
  policy = data.aws_iam_policy_document.ggjam-content-bucket-policy.json
}

resource "aws_iam_user" "ggjam-content" {
  name = "ggjam-content"
  path = "/system/"
}

resource "aws_iam_access_key" "ggjam-content" {
  user = aws_iam_user.ggjam-content.name
}

data "aws_iam_policy_document" "ggjam-content" {
  statement {
    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.ggjam-content.arn
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:PutObjectVersionAcl",
      "s3:DeleteObject",
      "s3:PutObjectAcl"
    ]

    resources = [
      "${aws_s3_bucket.ggjam-content.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "ggjam-content" {
  name        = "ggjam-content"
  description = "Ghost Content Storage Policy"
  path        = "/service-role/"
  policy      = data.aws_iam_policy_document.ggjam-content.json
}

resource "aws_iam_policy_attachment" "ggjam-content" {
  name       = "ggjam-content"
  users      = [aws_iam_user.ggjam-content.name]
  policy_arn = aws_iam_policy.ggjam-content.arn
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
    image          = "wunderhund/ghost-s3:latest"
    site_name      = var.site_name
    port           = var.ghost_port
    db_host        = aws_db_instance.ghost.address
    db_client      = var.ghostdb_client
    db_user        = var.ghostdb_user
    db_pass        = var.ghostdb_pass
    db_database    = var.ghostdb_database
    log_group      = aws_cloudwatch_log_group.ghost_cloudwatch.name
    region         = data.aws_region.current.name
    content_bucket = aws_s3_bucket.ggjam-content.bucket
    accesskey      = aws_iam_access_key.ggjam-content.id
    secretkey      = aws_iam_access_key.ggjam-content.secret
  })
  
  tags = merge(
    {
      Name = "ghost"
    },
    var.base_tags
  )
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

