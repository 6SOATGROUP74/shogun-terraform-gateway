resource "aws_api_gateway_authorizer" "gateway_auth" {
  name                   = "GatewayAuth"
  rest_api_id            = aws_api_gateway_rest_api.this.id
  identity_source        = "method.request.header.Documento"
  authorizer_uri         = aws_lambda_function.lambda_auth.invoke_arn
  authorizer_credentials = local.lab_role
  type                   = "REQUEST"
}

resource "aws_api_gateway_resource" "resource_gateway" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "mydemoresource"
}

resource "aws_api_gateway_method" "gateway_method" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.resource_gateway.id
  http_method   = "GET"
  authorization = "NONE"
}

data "template_file" "user_api_swagger" {
  template = file("source/swagger/swagger.yaml")
}


resource "aws_api_gateway_rest_api" "this" {
  name = "auth-demo"
  body = data.template_file.user_api_swagger.rendered
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}


data "aws_iam_policy_document" "invocation_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}



resource "aws_lambda_function" "lambda_auth" {
  filename         = "source/lambda.zip"
  function_name    = "lambda_api_gateway_auth"
  role             =  local.lab_role
  handler          = "lambda.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("source/lambda.zip")

  environment {
    variables = {
      cognito_id = aws_cognito_user_pool.pool.id
    }
  }

}