[
  {
    "name": "ghost",
    "image": "ghost:3.13.1",
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
        "name": "database__client",
        "value": "mysql"
      },
      {
        "name": "database__connection__host",
        "value": "${host}"
      },
      {
        "name": "database__connection__user",
        "value": "${user}"
      },
      {
        "name": "database__connection__password",
        "value": "${pass}"
      },
      {
        "name": "database__connection__database",
        "value": "ghostdb"
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