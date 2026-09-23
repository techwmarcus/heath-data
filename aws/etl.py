import json
import boto3
from datetime import datetime

s3 = boto3.client("s3")

SOURCE_BUCKET = "fhir-bucket-amarri"
DEST_BUCKET = "fhir-bucket-amarri"


def read_json_from_s3(bucket, key):
    response = s3.get_object(
        Bucket=bucket,
        Key=key
    )

    data = response["Body"].read().decode("utf-8")

    return json.loads(data)


def write_json_to_s3(bucket, key, data):
    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=json.dumps(data, indent=2),
        ContentType="application/json"
    )


# -----------------------------
# Patient ETL
# -----------------------------

def transform_patients(data):

    transformed = []

    for patient in data:

        name = patient.get("name", [{}])[0]

        transformed.append({
            "patient_id": patient.get("id"),

            "first_name": (
                name.get("given", [""])[0]
                if name.get("given")
                else ""
            ),

            "last_name": (
                name.get("family", "")
            ),

            "gender": patient.get("gender"),

            "birth_date": patient.get("birthDate"),

            "active": patient.get("active"),

            "resource_type": patient.get("resourceType")
        })

    return transformed


# -----------------------------
# Encounter ETL
# -----------------------------

def transform_encounters(data):

    transformed = []

    for encounter in data:

        period = encounter.get("period", {})

        reason = encounter.get("reason", [])

        if isinstance(reason, list) and reason:
            reason_text = reason[0].get("text")
        elif isinstance(reason, dict):
            reason_text = reason.get("text")
        else:
            reason_text = None

        transformed.append({
            "encounter_id": encounter.get("id"),

            "patient_id": (
                encounter.get("subject", {})
                .get("reference", "")
                .replace("Patient/", "")
            ),

            "period_start": period.get("start"),

            "period_end": period.get("end"),

            "reason": reason_text,

            "status": encounter.get("status"),

            "resource_type": encounter.get("resourceType")
        })

    return transformed


# -----------------------------
# Observation ETL
# -----------------------------

def transform_observations(data):

    transformed = []

    for observation in data:

        value_quantity = observation.get(
            "valueQuantity",
            {}
        )

        transformed.append({
            "observation_id": observation.get("id"),

            "patient_id": (
                observation.get("subject", {})
                .get("reference", "")
                .replace("Patient/", "")
            ),

            "observation_code": (
                observation.get("code", {})
                .get("coding", [{}])[0]
                .get("code")
            ),

            "observation_name": (
                observation.get("code", {})
                .get("text")
            ),

            "value": value_quantity.get("value"),

            "unit": value_quantity.get("unit"),

            "effective_date": observation.get(
                "effectiveDateTime"
            ),

            "status": observation.get("status"),

            "resource_type": observation.get("resourceType")
        })

    return transformed


# -----------------------------
# Lambda
# -----------------------------

def lambda_handler(event, context):

    # Read raw FHIR JSON
    patients = read_json_from_s3(
        SOURCE_BUCKET,
        "raw/patients-test-data.json"
    )

    encounters = read_json_from_s3(
        SOURCE_BUCKET,
        "raw/encounters-test-data.json"
    )

    observations = read_json_from_s3(
        SOURCE_BUCKET,
        "raw/observations-test-data.json"
    )

    # Transform
    patients_clean = transform_patients(patients)

    encounters_clean = transform_encounters(encounters)

    observations_clean = transform_observations(observations)

    # Write processed data
    write_json_to_s3(
        DEST_BUCKET,
        "processed/patients.json",
        patients_clean
    )

    write_json_to_s3(
        DEST_BUCKET,
        "processed/encounters.json",
        encounters_clean
    )

    write_json_to_s3(
        DEST_BUCKET,
        "processed/observations.json",
        observations_clean
    )

    return {
        "statusCode": 200,
        "body": {
            "message": "FHIR ETL completed successfully",
            "patients": len(patients_clean),
            "encounters": len(encounters_clean),
            "observations": len(observations_clean)
        }
    }