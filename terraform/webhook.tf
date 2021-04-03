resource "aws_iam_role" "TriggerBuild-Lambda" {
  name               = "TriggerBuild-Lambda"
  description        = "Allows Lambda functions to call AWS services on your behalf."
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
              "Service": "lambda.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda-basic" {
  role       = aws_iam_role.TriggerBuild-Lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda-codebuild" {
  role       = aws_iam_role.TriggerBuild-Lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

data "archive_file" "lambda_function" {
  type = "zip"
  source {
    content = templatefile("templates/lambda_function.py.tpl", {
      codebuild_project = aws_codebuild_project.ggjam_frontend.name
    })
    filename = "lambda_function.py"
  }
  output_path = "files/lambda_function.zip"
}

resource "aws_lambda_function" "TriggerBuild" {
  runtime          = "python3.8"
  filename         = data.archive_file.lambda_function.output_path
  source_code_hash = data.archive_file.lambda_function.output_base64sha256
  function_name    = "TriggerBuild"
  role             = aws_iam_role.TriggerBuild-Lambda.arn
  handler          = "lambda_function.entrypoint"
}

resource "aws_security_group" "ghost-vpc-endpoint" {
  name        = "ghost-vpc-endpoint"
  description = "Security Group for Ghost Webhook VPC Endpoint"
  vpc_id      = aws_vpc.ggjam.id

  ingress {
    description     = "Webhook Access"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ghost.id, aws_security_group.jumpbox.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "ghost-vpc-endpint"
    },
    var.base_tags
  )
}

resource "aws_vpc_endpoint" "ghost-vpc-endpoint" {
  vpc_id              = aws_vpc.ggjam.id
  service_name        = "com.amazonaws.${var.region}.execute-api"
  auto_accept         = true
  private_dns_enabled = true
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.ghost-vpc-endpoint.id]
  subnet_ids          = [aws_subnet.private-a.id, aws_subnet.private-b.id]

}

data "aws_iam_policy_document" "api-webhook" {
  statement {
    actions = [
      "execute-api:Invoke"
    ]

    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      "arn:aws:execute-api:us-west-2:925412914118:9xygkt8j2a/*"
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpc"

      values = [
        aws_vpc.ggjam.id
      ]
    }
  }

  statement {
    actions = [
      "execute-api:Invoke"
    ]

    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      "arn:aws:execute-api:us-west-2:925412914118:9xygkt8j2a/*"
    ]
  }
}

resource "aws_api_gateway_rest_api" "TriggerBuild-Private" {
  name        = "TriggerBuild-Private"
  description = "Like TriggerBuild, but Private"
  policy      = data.aws_iam_policy_document.api-webhook.json

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.ghost-vpc-endpoint.id]
  }
}

resource "aws_api_gateway_method" "TriggerBuild-Private" {
  rest_api_id   = aws_api_gateway_rest_api.TriggerBuild-Private.id
  resource_id   = aws_api_gateway_rest_api.TriggerBuild-Private.root_resource_id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "TriggerBuild-Private" {
  rest_api_id             = aws_api_gateway_rest_api.TriggerBuild-Private.id
  resource_id             = aws_api_gateway_rest_api.TriggerBuild-Private.root_resource_id
  http_method             = aws_api_gateway_method.TriggerBuild-Private.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  content_handling        = "CONVERT_TO_TEXT"
  passthrough_behavior    = "WHEN_NO_MATCH"
  uri                     = aws_lambda_function.TriggerBuild.invoke_arn
}

resource "aws_lambda_permission" "TriggerBuild" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.TriggerBuild.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.TriggerBuild-Private.id}/*/${aws_api_gateway_method.TriggerBuild-Private.http_method}/}"
}

resource "aws_api_gateway_deployment" "TriggerBuild-Private" {
  depends_on  = [aws_api_gateway_integration.TriggerBuild-Private]
  rest_api_id = aws_api_gateway_rest_api.TriggerBuild-Private.id
  stage_name  = "prod"
}

resource "aws_api_gateway_stage" "TriggerBuild-Private" {
  stage_name    = "TriggerBuild-Private"
  rest_api_id   = aws_api_gateway_rest_api.TriggerBuild-Private.id
  deployment_id = aws_api_gateway_deployment.TriggerBuild-Private.id
}