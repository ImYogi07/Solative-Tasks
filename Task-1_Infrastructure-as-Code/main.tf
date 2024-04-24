# Define the AWS provider
provider "aws" {
  region = "us-east-1" # Choose the appropriate AWS region
}

# Create an S3 bucket to store media files
resource "aws_s3_bucket" "media_bucket" {
  bucket_prefix = "media-streaming-app"
  acl           = "private"
}

# Create a Lambda function to handle media streaming logic
resource "aws_lambda_function" "media_function" {
  function_name    = "media-streaming-function"
  handler          = "index.handler"
  runtime          = "nodejs14.x" # Choose the appropriate runtime
  memory_size      = 512
  timeout          = 30
  role             = aws_iam_role.lambda_role.arn

  # Assuming your Lambda function code is in a directory named "lambda_code"
  filename         = "lambda_code.zip"
  source_code_hash = filebase64sha256("lambda_code.zip")
}

# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "media-lambda-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement": [
      {
        "Effect"   : "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action"   : "sts:AssumeRole"
      }
    ]
  })
}

# Attach a policy to the Lambda role to allow access to S3
resource "aws_iam_policy_attachment" "lambda_s3_policy" {
  name       = "lambda-s3-policy"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  roles      = [aws_iam_role.lambda_role.name]
}

# Create an API Gateway to expose Lambda function as an HTTP endpoint
resource "aws_api_gateway_rest_api" "media_api" {
  name        = "media-streaming-api"
  description = "API for media streaming application"
}

resource "aws_api_gateway_resource" "media_resource" {
  rest_api_id = aws_api_gateway_rest_api.media_api.id
  parent_id   = aws_api_gateway_rest_api.media_api.root_resource_id
  path_part   = "stream"
}

resource "aws_api_gateway_method" "media_method" {
  rest_api_id   = aws_api_gateway_rest_api.media_api.id
  resource_id   = aws_api_gateway_resource.media_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "media_integration" {
  rest_api_id             = aws_api_gateway_rest_api.media_api.id
  resource_id             = aws_api_gateway_resource.media_resource.id
  http_method             = aws_api_gateway_method.media_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.media_function.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.media_function.function_name
  principal     = "apigateway.amazonaws.com"

  # Restrict the API Gateway to invoke the Lambda function only for this resource
  source_arn = "${aws_api_gateway_rest_api.media_api.execution_arn}//"
}

# Output the API Gateway endpoint URL
output "api_gateway_url" {
  value = aws_api_gateway_rest_api.media_api.invoke_url
}
