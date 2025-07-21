provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "data_bucket" {
  bucket = "event-pipeline-storage"
  force_destroy = true
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_lambda_function" "process_data" {
  timeout = 30
  function_name = "ingestLambda"
  filename      = "lambda.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn
  source_code_hash = filebase64sha256("lambda.zip")
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "event-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.process_data.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /ingest"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_data.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
resource "aws_iam_policy" "lambda_s3_policy" {
  name = "lambda_s3_write_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:PutObject"],
        Resource = "arn:aws:s3:::event-pipeline-storage/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}
resource "aws_lambda_function" "report_data" {
  timeout = 30
  function_name = "reportLambda"
  filename      = "report_lambda.zip"
  handler       = "report_lambda.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn
  source_code_hash = filebase64sha256("report_lambda.zip")
}

resource "aws_iam_policy" "athena_ses_policy" {
  name = "athena-ses-lambda-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "athena:*",
          "glue:*",
          "s3:*",
          "ses:SendEmail",
          "ses:SendRawEmail"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_athena_ses" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.athena_ses_policy.arn
}

# CloudWatch Event to trigger daily
resource "aws_cloudwatch_event_rule" "daily_report" {
  name                = "daily-summary"
  schedule_expression = "rate(1 day)"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.report_data.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_report.arn
}

resource "aws_cloudwatch_event_target" "trigger_report_lambda" {
  rule      = aws_cloudwatch_event_rule.daily_report.name
  target_id = "dailyReportTarget"
  arn       = aws_lambda_function.report_data.arn
}
