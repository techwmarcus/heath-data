resource "aws_iam_role" "fhir_role" {
  name = "fhir_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_iam_role_policy" "fhir_s3_policy" {
  name = "fhir_s3_policy"
  role = aws_iam_role.fhir_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.fhir.arn}/raw/*"
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

resource "aws_iam_role_policy" "fhir_logging_policy" {
  name = "fhir_logging_policy"
  role = aws_iam_role.fhir_role.id

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


resource "aws_glue_crawler" "fhir_crawler" {
  database_name = aws_glue_catalog_database.fhir.name
  name          = "fhir_crawler"
  role          = aws_iam_role.fhir_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.fhir.bucket}/raw/"
  }
}

resource "aws_glue_catalog_database" "fhir" {
  name = "fhir"
}