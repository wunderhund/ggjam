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
        "value": "http://ggjam.craigabutler.com"
      },
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
        "value": "${bucket}"
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