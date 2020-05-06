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
        "name": "database__connection__host",
        "value": "${host}"
      }
    ]
  }
]