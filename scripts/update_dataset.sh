#!/usr/bin/env bash
set -e

LOCATION="$1"
PROCESSOR_ID="$2"
BUCKET_NAME="$3"

if [ -z "$LOCATION" ] || [ -z "$PROCESSOR_ID" ] || [ -z "$BUCKET_NAME" ]; then
  echo "Usage: $0 <location> <processor_id> <bucket_name>"
  exit 1
fi

echo "Initializing/updating dataset for processor: ${PROCESSOR_ID} with storage bucket: ${BUCKET_NAME}..."
ACCESS_TOKEN=$(gcloud auth print-access-token)

GCS_URI="gs://${BUCKET_NAME}/dataset/"

RESPONSE=$(curl -s -X PATCH \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"gcsManagedConfig\": {
      \"gcsPrefix\": {
        \"gcsUriPrefix\": \"${GCS_URI}\"
      }
    }
  }" \
  "https://${LOCATION}-documentai.googleapis.com/v1beta3/${PROCESSOR_ID}/dataset?updateMask=gcsManagedConfig")

echo "Response: $RESPONSE"
