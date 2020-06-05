[
  {
    "name": "ghost",
    "image": "${image}",
    "cpu": 256,
    "memory": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${port},
        "hostPort": ${port}
      }
    ],
    "environment": [
      {
        "name": "url",
        "value": "http://${site_name}"
      },
      {
        "name": "database__client",
        "value": "${db_client}"
      },
      {
        "name": "database__connection__host",
        "value": "${db_host}"
      },
      {
        "name": "database__connection__user",
        "value": "${db_user}"
      },
      {
        "name": "database__connection__password",
        "value": "${db_pass}"
      },
      {
        "name": "database__connection__database",
        "value": "${db_database}"
      },
      {
        "name": "storage__active",
        "value": "s3"
      },
      {
        "name": "storage__s3__accessKeyId",
        "value": "${accesskey}"
      },
      {
        "name": "storage__s3__secretAccessKey",
        "value": "${secretkey}"
      },
      {
        "name": "storage__s3__region",
        "value": "${region}"
      },
      {
        "name": "storage__s3__bucket",
        "value": "${content_bucket}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]