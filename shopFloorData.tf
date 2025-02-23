## shopFloorData Lambda Execution Role ##

resource "aws_iam_policy" "shopFloorData_lambda_policy" {
  name        = "shopFloorData_lambda_policy"
  path        = "/"
  description = "Policy to be attached to ShopFloorData_TxnService lambda"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "logs:*",
          "dynamodb:*"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role" "shopFloorData_lambda_role" {
  name = "shopFloorData_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "shopFloorData_lambda_role_attach" {
  role       = aws_iam_role.shopFloorData_lambda_role.name
  policy_arn = aws_iam_policy.shopFloorData_lambda_policy.arn
}

## shopFloorData Lambda Fucntion ##

data "archive_file" "lambdadata" {
  type        = "zip"
  source_file = "${path.module}/lambdaData/shopFloorData/index.js"
  output_path = "shopFloorData.zip"
}

resource "aws_lambda_function" "shopFloorData_txnService" {
  function_name = "ShopFloorData_TxnService"
  role          = aws_iam_role.shopFloorData_lambda_role.arn
  runtime       = "nodejs16.x"
  filename      = "shopFloorData.zip"
  handler       = "index.handler"
  timeout       = "15"

  source_code_hash = data.archive_file.lambdadata.output_base64sha256

}

## AWI API Gateway ##

resource "aws_api_gateway_rest_api" "shopFloor_api_gw" {
  name        = "shopFloor_api_gw"
  description = "REST API to CRUD Shop Floor Data"
}

resource "aws_api_gateway_resource" "shopFloor_resource" {
  rest_api_id = aws_api_gateway_rest_api.shopFloor_api_gw.id
  parent_id   = aws_api_gateway_rest_api.shopFloor_api_gw.root_resource_id
  path_part   = "shopFloorData"
}

## Post HTTP Method #

resource "aws_api_gateway_method" "post_shopFloor_data" {
  rest_api_id   = aws_api_gateway_rest_api.shopFloor_api_gw.id
  resource_id   = aws_api_gateway_resource.shopFloor_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "post_shopFloor_data_response_200" {
  rest_api_id = aws_api_gateway_rest_api.shopFloor_api_gw.id
  resource_id = aws_api_gateway_resource.shopFloor_resource.id
  http_method = aws_api_gateway_method.post_shopFloor_data.http_method
  status_code = 200

  /**
   * This is where the configuration for CORS enabling starts.
   * We need to enable those response parameters and in the 
   * integration response we will map those to actual values
   */
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true,
    "method.response.header.Access-Control-Allow-Methods"     = true,
    "method.response.header.Access-Control-Allow-Origin"      = true,
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
}

resource "aws_api_gateway_integration" "integration_post_shopFloor_data" {
  rest_api_id             = aws_api_gateway_rest_api.shopFloor_api_gw.id
  resource_id             = aws_api_gateway_resource.shopFloor_resource.id
  http_method             = aws_api_gateway_method.post_shopFloor_data.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.shopFloorData_txnService.invoke_arn
}

## Get HTTP Method ##

resource "aws_api_gateway_method" "get_shopFloor_data" {
  rest_api_id   = aws_api_gateway_rest_api.shopFloor_api_gw.id
  resource_id   = aws_api_gateway_resource.shopFloor_resource.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.Plant" = true,
    "method.request.querystring.Line"  = true
  }
}

resource "aws_api_gateway_method_response" "get_shopFloor_data_response_200" {
  rest_api_id = aws_api_gateway_rest_api.shopFloor_api_gw.id
  resource_id = aws_api_gateway_resource.shopFloor_resource.id
  http_method = aws_api_gateway_method.get_shopFloor_data.http_method
  status_code = 200

  /**
   * This is where the configuration for CORS enabling starts.
   * We need to enable those response parameters and in the 
   * integration response we will map those to actual values
   */
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true,
    "method.response.header.Access-Control-Allow-Methods"     = true,
    "method.response.header.Access-Control-Allow-Origin"      = true,
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
}

resource "aws_api_gateway_integration" "integration_get_shopFloor_data" {
  rest_api_id             = aws_api_gateway_rest_api.shopFloor_api_gw.id
  resource_id             = aws_api_gateway_resource.shopFloor_resource.id
  http_method             = aws_api_gateway_method.get_shopFloor_data.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.shopFloorData_txnService.invoke_arn
}

## Delete HTTP Method ##

resource "aws_api_gateway_method" "delete_shopFloor_data" {
  rest_api_id   = aws_api_gateway_rest_api.shopFloor_api_gw.id
  resource_id   = aws_api_gateway_resource.shopFloor_resource.id
  http_method   = "DELETE"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.Plant"   = true,
    "method.request.querystring.Line"    = true,
    "method.request.querystring.KpiName" = true
  }
}

resource "aws_api_gateway_method_response" "delete_shopFloor_data_response_200" {
  rest_api_id = aws_api_gateway_rest_api.shopFloor_api_gw.id
  resource_id = aws_api_gateway_resource.shopFloor_resource.id
  http_method = aws_api_gateway_method.delete_shopFloor_data.http_method
  status_code = 200

  /**
   * This is where the configuration for CORS enabling starts.
   * We need to enable those response parameters and in the 
   * integration response we will map those to actual values
   */
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true,
    "method.response.header.Access-Control-Allow-Methods"     = true,
    "method.response.header.Access-Control-Allow-Origin"      = true,
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
}

resource "aws_api_gateway_integration" "integration_delete_shopFloor_data" {
  rest_api_id             = aws_api_gateway_rest_api.shopFloor_api_gw.id
  resource_id             = aws_api_gateway_resource.shopFloor_resource.id
  http_method             = aws_api_gateway_method.delete_shopFloor_data.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.shopFloorData_txnService.invoke_arn
}


## shopFloorData Lambda Function ##

resource "aws_lambda_permission" "shopFloorData_apigw_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.shopFloorData_txnService.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.shopFloor_api_gw.execution_arn}/*"
}

module "cors" {
  source = "./modules/cors"

  api_id            = aws_api_gateway_rest_api.shopFloor_api_gw.id
  api_resource_id   = aws_api_gateway_resource.shopFloor_resource.id
  allow_credentials = true
}

resource "aws_api_gateway_deployment" "shopFloorData_api_deploy" {
  rest_api_id = aws_api_gateway_rest_api.shopFloor_api_gw.id
  triggers = {
    redeployment = sha1(jsonencode([

      aws_api_gateway_resource.shopFloor_resource,
      aws_api_gateway_method.post_shopFloor_data,
      aws_api_gateway_integration.integration_post_shopFloor_data,
      aws_api_gateway_method.get_shopFloor_data,
      aws_api_gateway_integration.integration_get_shopFloor_data,
      aws_api_gateway_method.delete_shopFloor_data,
      aws_api_gateway_integration.integration_delete_shopFloor_data,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_api_gateway_stage" "stage-andon-api" {
  deployment_id = aws_api_gateway_deployment.shopFloorData_api_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.shopFloor_api_gw.id
  stage_name    = "dev"
}