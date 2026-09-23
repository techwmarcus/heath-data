resource "aws_athena_database" "athena-db" {
  name   = "database"
  bucket = aws_s3_bucket.fhir.id
}

resource "aws_athena_workgroup" "fhir_analytics" {
  name = "fhir-analytics"

  configuration {
    enforce_workgroup_configuration = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.fhir.bucket}/processed/"
    }
  }
}


resource "aws_athena_named_query" "patients" {
  name      = "patients-query"
  database  = aws_glue_catalog_database.fhir.name
  workgroup = aws_athena_workgroup.fhir_analytics.name

  query = "SELECT * FROM patients LIMIT 100"
}




