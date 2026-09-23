resource "aws_lambda_function" "etl_lambda" {
  function_name = "fhir_etl_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "crawler.lambda_handler"
  runtime       = "python3.9"

  filename      = "${path.module}/crawler.zip"

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.fhir.bucket
      GLUE_DATABASE  = aws_glue_catalog_database.fhir.name
    }
  }
  
}


resource "aws_lambda_function" "etl_function_lambda" {
  function_name = "etl_function_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "etl.lambda_handler"
  runtime       = "python3.9"

  filename      = "${path.module}/etl.zip"

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.fhir.bucket
      GLUE_DATABASE  = aws_glue_catalog_database.fhir.name
    }
  }
  
}




resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "glue.amazonaws.com",
            "scheduler.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_glue_service" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "lambda_s3_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:*",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.fhir.arn}/*"
      },
      {
        Action = [
          "glue:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy" "lambda_logging_policy" {
  name = "lambda_logging_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_scheduler_schedule" "fhir-scheduler" {
  name       = "my-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }


  schedule_expression = "rate(1 minute)"

  target {
    arn      = aws_lambda_function.etl_lambda.arn
    role_arn = aws_iam_role.scheduler-role.arn
  }
}

resource "aws_scheduler_schedule" "fhir-etl-scheduler" {
  name       = "etl-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }


  schedule_expression = "rate(1 minute)"

  target {
    arn      = aws_lambda_function.etl_function_lambda.arn
    role_arn = aws_iam_role.scheduler-role.arn
  }
}

resource "aws_iam_role" "scheduler-role" {
  name = "scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "scheduler.amazonaws.com"
          ]
        }
      }
    ]
  })
}


resource "aws_iam_role_policy" "lambda-invoke-policy" {
  name        = "lambda-invoke-policy"
  role        = aws_iam_role.scheduler-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = "${aws_lambda_function.etl_lambda.arn}"
      },
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = "${aws_lambda_function.etl_function_lambda.arn}"
      }
    ]
  })
}