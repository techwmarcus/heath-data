resource "aws_s3_bucket" "fhir" {
  bucket = "fhir-bucket-amarri"
  region = "us-west-1"

  tags = {
    Name        = "fhir"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "fhir" {
  bucket = aws_s3_bucket.fhir.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_versioning" "fhir" {
  bucket = aws_s3_bucket.fhir.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "raw_folder" {
  bucket = aws_s3_bucket.fhir.id
  key    = "raw/"
}

resource "aws_s3_object" "processed_folder" {
  bucket = aws_s3_bucket.fhir.id
  key    = "processed/"
}


resource "aws_s3_bucket_policy" "fhir" {
  bucket = aws_s3_bucket.fhir.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "${aws_s3_bucket.fhir.arn}"
      },
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.fhir.arn}/*"
      }
    ]
  })

}

resource "aws_s3_object" "encounters-test-data" {
  bucket = aws_s3_bucket.fhir.id
  key    = "raw/encounters-test-data.json"
  source ="${path.module}/encounters.json"

  content_type = "application/json"
}

resource "aws_s3_object" "observations-test-data" {
  bucket = aws_s3_bucket.fhir.id
  key    = "raw/observations-test-data.json"
  source ="${path.module}/observations.json"

  content_type = "application/json"

}

resource "aws_s3_object" "patients-test-data" {
  bucket = aws_s3_bucket.fhir.id
  key    = "raw/patients-test-data.json"
  source ="${path.module}/patients.json"


  content_type = "application/json"
}

