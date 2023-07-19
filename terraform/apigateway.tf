/* Deploy API Gateway */

/* API GATEWAY POLICY */
resource "aws_iam_policy" "apigateway-lambda-policy" {
  name = "translator-api-gateway-policy1"

  policy = templatefile("./templates/lambda_invocation_policy.json", {
    arn_lambda1 = aws_lambda_function.insert-bad-translation.arn,
    arn_lambda2 = aws_lambda_function.insert-possible-better-translation.arn,
    arn_lambda3 = aws_lambda_function.read-bad-translations.arn,
    arn_lambda4 = aws_lambda_function.read-possible-better-translation-by-id.arn,
    arn_lambda5 = aws_lambda_function.vote-possible-better-translation.arn})
}

/* API GATEWAY IAM ROLE  */
resource "aws_iam_role" "apigateway-role" {
  name = "apigateway-role1"

  assume_role_policy = templatefile("./templates/api_gateway_role.json", {})
}

resource "aws_iam_policy" "apigateway-cloudwatch-policy" {
  name        = "translator-logger1"
  description = "IAM policy for API Gateway logging to Cloudwatch"
  path        = "/"

  policy = templatefile("./templates/apigateway_cloudwatch_policy.json", {})
}

/* API GATEWAY ROLE ATTACHMENT */
resource "aws_iam_role_policy_attachment" "apigateway-role-policy-attach1" {
  role       = aws_iam_role.apigateway-role.name
  policy_arn = aws_iam_policy.apigateway-lambda-policy.arn
}
resource "aws_iam_role_policy_attachment" "apigateway-role-policy-attach2" {
  role       = aws_iam_role.apigateway-role.name
  policy_arn = aws_iam_policy.apigateway-cloudwatch-policy.arn
}

/* API GATEWAY CONFIG */
resource "aws_api_gateway_rest_api" "rest-apigateway" {
  name        = "translator-apigateway"
  description = "API Gateway to interact with database and translator server through lambdas"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Environment = "Production"
    Name        = "API Gateway"
  }
}

resource "aws_api_gateway_account" "apigateway-settings" {
  #to connect Cloudwatch with APIGW in order to enable log groups directly
  cloudwatch_role_arn = aws_iam_role.apigateway-role.arn
}

/* INSERT BAD TRANSLATION RESOURCE */
resource "aws_api_gateway_resource" "insert-bad-translation-resource" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  parent_id   = aws_api_gateway_rest_api.rest-apigateway.root_resource_id
  path_part   = "insert-bad-translation"
}

resource "aws_api_gateway_method" "insert-bad-translation-post-method" {
  rest_api_id   = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id   = aws_api_gateway_resource.insert-bad-translation-resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "insert-bad-translation-post-method-response" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.insert-bad-translation-resource.id
  http_method = aws_api_gateway_method.insert-bad-translation-post-method.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "insert-bad-translation-post-integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id             = aws_api_gateway_resource.insert-bad-translation-resource.id
  http_method             = aws_api_gateway_method.insert-bad-translation-post-method.http_method
  integration_http_method = "POST"
  type                    = "AWS"

  uri         = aws_lambda_function.insert-bad-translation.invoke_arn
  credentials = aws_iam_role.apigateway-role.arn
}

resource "aws_api_gateway_integration_response" "insert-bad-translation-post-method-response-integration" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.insert-bad-translation-resource.id
  http_method = aws_api_gateway_method.insert-bad-translation-post-method.http_method
  status_code = aws_api_gateway_method_response.insert-bad-translation-post-method-response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

#  response_templates = {
#    "application/json" = "Empty"
#  }

  depends_on = [
    aws_api_gateway_method.insert-bad-translation-post-method,
    aws_api_gateway_method_response.insert-bad-translation-post-method-response,
    aws_api_gateway_integration.insert-bad-translation-post-integration
  ]
}

resource "aws_api_gateway_method" "insert-bad-translation-options-method" {
  rest_api_id   = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id   = aws_api_gateway_resource.insert-bad-translation-resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "insert-bad-translation-options-method-response" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.insert-bad-translation-resource.id
  http_method = aws_api_gateway_method.insert-bad-translation-options-method.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "insert-bad-translation-options-integration" {
  rest_api_id      = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id      = aws_api_gateway_resource.insert-bad-translation-resource.id
  http_method      = aws_api_gateway_method.insert-bad-translation-options-method.http_method
  type             = "MOCK"
  content_handling = "CONVERT_TO_TEXT"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_integration_response" "insert-bad-translation-options-integration-response" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.insert-bad-translation-resource.id
  http_method = aws_api_gateway_method.insert-bad-translation-options-method.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.insert-bad-translation-options-integration,
    aws_api_gateway_method_response.insert-bad-translation-options-method-response
  ]
}

/* INSERT POSSIBLE BETTER TRANSLATION RESOURCE */
resource "aws_api_gateway_resource" "insert-possible-better-translation-resource" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  parent_id   = aws_api_gateway_rest_api.rest-apigateway.root_resource_id
  path_part   = "insert-possible-better-translation"
}

resource "aws_api_gateway_method" "insert-possible-better-translation-post-method" {
  rest_api_id   = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id   = aws_api_gateway_resource.insert-possible-better-translation-resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "insert-possible-better-translation-post-method-response" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.insert-possible-better-translation-resource.id
  http_method = aws_api_gateway_method.insert-possible-better-translation-post-method.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "insert-possible-better-translation-post-integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id             = aws_api_gateway_resource.insert-possible-better-translation-resource.id
  http_method             = aws_api_gateway_method.insert-possible-better-translation-post-method.http_method
  integration_http_method = "POST"
  type                    = "AWS"

  uri         = aws_lambda_function.insert-possible-better-translation.invoke_arn
  credentials = aws_iam_role.apigateway-role.arn
}

resource "aws_api_gateway_integration_response" "insert-possible-better-translation-post-method-response-integration" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.insert-possible-better-translation-resource.id
  http_method = aws_api_gateway_method.insert-possible-better-translation-post-method.http_method
  status_code = aws_api_gateway_method_response.insert-possible-better-translation-post-method-response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

#  response_templates = {
#    "application/json" = "Empty"
#  }

  depends_on = [
    aws_api_gateway_method.insert-possible-better-translation-post-method,
    aws_api_gateway_method_response.insert-possible-better-translation-post-method-response,
    aws_api_gateway_integration.insert-possible-better-translation-post-integration
  ]
}

resource "aws_api_gateway_method" "insert-possible-better-translation-options-method" {
  rest_api_id   = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id   = aws_api_gateway_resource.insert-possible-better-translation-resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "insert-possible-better-translation-options-method-response" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.insert-possible-better-translation-resource.id
  http_method = aws_api_gateway_method.insert-possible-better-translation-options-method.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "insert-possible-better-translation-options-integration" {
  rest_api_id      = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id      = aws_api_gateway_resource.insert-possible-better-translation-resource.id
  http_method      = aws_api_gateway_method.insert-possible-better-translation-options-method.http_method
  type             = "MOCK"
  content_handling = "CONVERT_TO_TEXT"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_integration_response" "insert-possible-better-translation-options-integration-response" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.insert-possible-better-translation-resource.id
  http_method = aws_api_gateway_method.insert-possible-better-translation-options-method.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.insert-possible-better-translation-options-integration,
    aws_api_gateway_method_response.insert-possible-better-translation-options-method-response
  ]
}

/* READ BAD TRANSLATION RESOURCE */
resource "aws_api_gateway_resource" "read-bad-translation-resource" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  parent_id   = aws_api_gateway_rest_api.rest-apigateway.root_resource_id
  path_part   = "read-bad-translation"
}

resource "aws_api_gateway_method" "read-bad-translation-post-method" {
  rest_api_id   = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id   = aws_api_gateway_resource.read-bad-translation-resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "read-bad-translation-post-method-response" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.read-bad-translation-resource.id
  http_method = aws_api_gateway_method.read-bad-translation-post-method.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "read-bad-translation-post-integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id             = aws_api_gateway_resource.read-bad-translation-resource.id
  http_method             = aws_api_gateway_method.read-bad-translation-post-method.http_method
  integration_http_method = "POST"
  type                    = "AWS"

  uri         = aws_lambda_function.read-bad-translations.invoke_arn
  credentials = aws_iam_role.apigateway-role.arn
}

resource "aws_api_gateway_integration_response" "read-bad-translation-post-method-response-integration" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.read-bad-translation-resource.id
  http_method = aws_api_gateway_method.read-bad-translation-post-method.http_method
  status_code = aws_api_gateway_method_response.read-bad-translation-post-method-response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

#  response_templates = {
#    "application/json" = "Empty"
#  }

  depends_on = [
    aws_api_gateway_method.read-bad-translation-post-method,
    aws_api_gateway_method_response.read-bad-translation-post-method-response,
    aws_api_gateway_integration.read-bad-translation-post-integration
  ]
}

resource "aws_api_gateway_method" "read-bad-translation-options-method" {
  rest_api_id   = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id   = aws_api_gateway_resource.read-bad-translation-resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "read-bad-translation-options-method-response" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.read-bad-translation-resource.id
  http_method = aws_api_gateway_method.read-bad-translation-options-method.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "read-bad-translation-options-integration" {
  rest_api_id      = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id      = aws_api_gateway_resource.read-bad-translation-resource.id
  http_method      = aws_api_gateway_method.read-bad-translation-options-method.http_method
  type             = "MOCK"
  content_handling = "CONVERT_TO_TEXT"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_integration_response" "read-bad-translation-options-integration-response" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.read-bad-translation-resource.id
  http_method = aws_api_gateway_method.read-bad-translation-options-method.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.read-bad-translation-options-integration,
    aws_api_gateway_method_response.read-bad-translation-options-method-response
  ]
}

/* READ POSSIBLE BETTER TRANSLATION RESOURCE */
resource "aws_api_gateway_resource" "read-possible-better-translation-resource" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  parent_id   = aws_api_gateway_rest_api.rest-apigateway.root_resource_id
  path_part   = "read-possible-better-translation"
}

resource "aws_api_gateway_method" "read-possible-better-translation-post-method" {
  rest_api_id   = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id   = aws_api_gateway_resource.read-possible-better-translation-resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "read-possible-better-translation-post-method-response" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.read-possible-better-translation-resource.id
  http_method = aws_api_gateway_method.read-possible-better-translation-post-method.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "read-possible-better-translation-post-integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id             = aws_api_gateway_resource.read-possible-better-translation-resource.id
  http_method             = aws_api_gateway_method.read-possible-better-translation-post-method.http_method
  integration_http_method = "POST"
  type                    = "AWS"

  uri         = aws_lambda_function.read-possible-better-translation-by-id.invoke_arn
  credentials = aws_iam_role.apigateway-role.arn
}

resource "aws_api_gateway_integration_response" "read-possible-better-translation-post-method-response-integration" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.read-possible-better-translation-resource.id
  http_method = aws_api_gateway_method.read-possible-better-translation-post-method.http_method
  status_code = aws_api_gateway_method_response.read-possible-better-translation-post-method-response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

#  response_templates = {
#    "application/json" = "Empty"
#  }

  depends_on = [
    aws_api_gateway_method.read-possible-better-translation-post-method,
    aws_api_gateway_method_response.read-possible-better-translation-post-method-response,
    aws_api_gateway_integration.read-possible-better-translation-post-integration
  ]
}

resource "aws_api_gateway_method" "read-possible-better-translation-options-method" {
  rest_api_id   = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id   = aws_api_gateway_resource.read-possible-better-translation-resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "read-possible-better-translation-options-method-response" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.read-possible-better-translation-resource.id
  http_method = aws_api_gateway_method.read-possible-better-translation-options-method.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "read-possible-better-translation-options-integration" {
  rest_api_id      = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id      = aws_api_gateway_resource.read-possible-better-translation-resource.id
  http_method      = aws_api_gateway_method.read-possible-better-translation-options-method.http_method
  type             = "MOCK"
  content_handling = "CONVERT_TO_TEXT"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_integration_response" "read-possible-better-translation-options-integration-response" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.read-possible-better-translation-resource.id
  http_method = aws_api_gateway_method.read-possible-better-translation-options-method.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.read-possible-better-translation-options-integration,
    aws_api_gateway_method_response.read-possible-better-translation-options-method-response
  ]
}


/* TRANSLATE API RESOURCE */
resource "aws_api_gateway_resource" "translate-api-resource" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  parent_id   = aws_api_gateway_rest_api.rest-apigateway.root_resource_id
  path_part   = "translate-api"
}

resource "aws_api_gateway_method" "translate-api-method" {
  rest_api_id   = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id   = aws_api_gateway_resource.translate-api-resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "translate-api-method-response" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.translate-api-resource.id
  http_method = aws_api_gateway_method.translate-api-method.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

# Create the VPC link
resource "aws_api_gateway_vpc_link" "gateway-to-backend-NLB" {
  name        = "my-vpc-link"
  description = "VPC link for API Gateway"
  target_arns = [aws_lb.network_load_balancer.arn]
}

resource "aws_api_gateway_integration" "translate-api-integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id             = aws_api_gateway_resource.translate-api-resource.id
  http_method             = aws_api_gateway_method.translate-api-method.http_method
  integration_http_method = "POST"
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_lb.application_load_balancer.dns_name}:8081/translate-api"
  credentials = aws_iam_role.apigateway-role.arn

  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.gateway-to-backend-NLB.id
}

resource "aws_api_gateway_method" "translate-api-options-method" {
  rest_api_id   = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id   = aws_api_gateway_resource.translate-api-resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "translate-api-options-method-response" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.translate-api-resource.id
  http_method = aws_api_gateway_method.translate-api-options-method.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "translate-api-options-integration" {
  rest_api_id      = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id      = aws_api_gateway_resource.translate-api-resource.id
  http_method      = aws_api_gateway_method.translate-api-options-method.http_method
  type             = "MOCK"
  content_handling = "CONVERT_TO_TEXT"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_integration_response" "translate-api-options-integration-response" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.translate-api-resource.id
  http_method = aws_api_gateway_method.translate-api-options-method.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.translate-api-options-integration,
    aws_api_gateway_method_response.translate-api-options-method-response
  ]
}

/* VOTE POSSIBLE BETTER TRANSLATION RESOURCE */
resource "aws_api_gateway_resource" "vote-possible-better-translation-resource" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  parent_id   = aws_api_gateway_rest_api.rest-apigateway.root_resource_id
  path_part   = "vote-possible-better-translation"
}

resource "aws_api_gateway_method" "vote-possible-better-translation-post-method" {
  rest_api_id   = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id   = aws_api_gateway_resource.vote-possible-better-translation-resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "vote-possible-better-translation-post-method-response" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.vote-possible-better-translation-resource.id
  http_method = aws_api_gateway_method.vote-possible-better-translation-post-method.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "vote-possible-better-translation-post-integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id             = aws_api_gateway_resource.vote-possible-better-translation-resource.id
  http_method             = aws_api_gateway_method.vote-possible-better-translation-post-method.http_method
  integration_http_method = "POST"
  type                    = "AWS"

  uri         = aws_lambda_function.vote-possible-better-translation.invoke_arn
  credentials = aws_iam_role.apigateway-role.arn
}

resource "aws_api_gateway_integration_response" "vote-possible-better-translation-post-method-response-integration" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.vote-possible-better-translation-resource.id
  http_method = aws_api_gateway_method.vote-possible-better-translation-post-method.http_method
  status_code = aws_api_gateway_method_response.vote-possible-better-translation-post-method-response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

#  response_templates = {
#    "application/json" = "Empty"
#  }

  depends_on = [
    aws_api_gateway_method.vote-possible-better-translation-post-method,
    aws_api_gateway_method_response.vote-possible-better-translation-post-method-response,
    aws_api_gateway_integration.vote-possible-better-translation-post-integration
  ]
}

resource "aws_api_gateway_method" "vote-possible-better-translation-options-method" {
  rest_api_id   = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id   = aws_api_gateway_resource.vote-possible-better-translation-resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "vote-possible-better-translation-options-method-response" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.vote-possible-better-translation-resource.id
  http_method = aws_api_gateway_method.vote-possible-better-translation-options-method.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "vote-possible-better-translation-options-integration" {
  rest_api_id      = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id      = aws_api_gateway_resource.vote-possible-better-translation-resource.id
  http_method      = aws_api_gateway_method.vote-possible-better-translation-options-method.http_method
  type             = "MOCK"
  content_handling = "CONVERT_TO_TEXT"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_integration_response" "vote-possible-better-translation-options-integration-response" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  resource_id = aws_api_gateway_resource.vote-possible-better-translation-resource.id
  http_method = aws_api_gateway_method.vote-possible-better-translation-options-method.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.vote-possible-better-translation-options-integration,
    aws_api_gateway_method_response.vote-possible-better-translation-options-method-response
  ]
}

/* CORS SECTION */
resource "aws_api_gateway_gateway_response" "cors_client_error" {
  rest_api_id   = aws_api_gateway_rest_api.rest-apigateway.id
  response_type = "DEFAULT_4XX"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'OPTIONS,GET,PUT,POST'"
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
  }
}
resource "aws_api_gateway_gateway_response" "cors_server_error" {
  rest_api_id   = aws_api_gateway_rest_api.rest-apigateway.id
  response_type = "DEFAULT_5XX"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'OPTIONS,GET,PUT,POST'"
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_deployment" "apigateway-deployment" {
  depends_on = [
    aws_api_gateway_method.insert-bad-translation-post-method,
    aws_api_gateway_integration.insert-bad-translation-post-integration,
    aws_api_gateway_integration_response.insert-bad-translation-post-method-response-integration,
    aws_api_gateway_method_response.insert-bad-translation-post-method-response,
    aws_api_gateway_method.insert-bad-translation-options-method,
    aws_api_gateway_integration.insert-bad-translation-options-integration,
    aws_api_gateway_integration_response.insert-bad-translation-options-integration-response,
    aws_api_gateway_method_response.insert-bad-translation-options-method-response,

    aws_api_gateway_method.insert-possible-better-translation-post-method,
    aws_api_gateway_integration.insert-possible-better-translation-post-integration,
    aws_api_gateway_integration_response.insert-possible-better-translation-post-method-response-integration,
    aws_api_gateway_method_response.insert-possible-better-translation-post-method-response,
    aws_api_gateway_method.insert-possible-better-translation-options-method,
    aws_api_gateway_integration.insert-possible-better-translation-options-integration,
    aws_api_gateway_integration_response.insert-possible-better-translation-options-integration-response,
    aws_api_gateway_method_response.insert-possible-better-translation-options-method-response,

    aws_api_gateway_method.read-bad-translation-post-method,
    aws_api_gateway_integration.read-bad-translation-post-integration,
    aws_api_gateway_integration_response.read-bad-translation-post-method-response-integration,
    aws_api_gateway_method_response.read-bad-translation-post-method-response,
    aws_api_gateway_method.read-bad-translation-options-method,
    aws_api_gateway_integration.read-bad-translation-options-integration,
    aws_api_gateway_integration_response.read-bad-translation-options-integration-response,
    aws_api_gateway_method_response.read-bad-translation-options-method-response,

    aws_api_gateway_method.read-possible-better-translation-post-method,
    aws_api_gateway_integration.read-possible-better-translation-post-integration,
    aws_api_gateway_integration_response.read-possible-better-translation-post-method-response-integration,
    aws_api_gateway_method_response.read-possible-better-translation-post-method-response,
    aws_api_gateway_method.read-possible-better-translation-options-method,
    aws_api_gateway_integration.read-possible-better-translation-options-integration,
    aws_api_gateway_integration_response.read-possible-better-translation-options-integration-response,
    aws_api_gateway_method_response.read-possible-better-translation-options-method-response,

    aws_api_gateway_method.vote-possible-better-translation-post-method,
    aws_api_gateway_integration.vote-possible-better-translation-post-integration,
    aws_api_gateway_integration_response.vote-possible-better-translation-post-method-response-integration,
    aws_api_gateway_method_response.vote-possible-better-translation-post-method-response,
    aws_api_gateway_method.vote-possible-better-translation-options-method,
    aws_api_gateway_integration.vote-possible-better-translation-options-integration,
    aws_api_gateway_integration_response.vote-possible-better-translation-options-integration-response,
    aws_api_gateway_method_response.vote-possible-better-translation-options-method-response,

    aws_api_gateway_method.translate-api-method,
    aws_api_gateway_integration.translate-api-integration,
    aws_api_gateway_method_response.translate-api-method-response,
    aws_api_gateway_method.translate-api-options-method,
    aws_api_gateway_integration.translate-api-options-integration,
    aws_api_gateway_integration_response.translate-api-options-integration-response,
    aws_api_gateway_method_response.translate-api-options-method-response
  ]
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.rest-apigateway.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "productionstage" {
  deployment_id = aws_api_gateway_deployment.apigateway-deployment.id
  rest_api_id   = aws_api_gateway_rest_api.rest-apigateway.id
  stage_name    = "prod"
}

resource "aws_api_gateway_method_settings" "stage-settings" {
  rest_api_id = aws_api_gateway_rest_api.rest-apigateway.id
  stage_name  = aws_api_gateway_stage.productionstage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    logging_level          = "ERROR"
    data_trace_enabled     = true
    throttling_burst_limit = 500
    throttling_rate_limit  = 50
  }
}

