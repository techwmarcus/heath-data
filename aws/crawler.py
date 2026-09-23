import boto3

glue = boto3.client("glue")

def lambda_handler(event, context):
    crawler_name = "fhir_crawler"

    try:
        glue.start_crawler(Name=crawler_name)

        return {
            "statusCode": 200,
            "body": f"Glue crawler '{crawler_name}' started successfully."
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": f"Failed to start crawler: {str(e)}"
        }