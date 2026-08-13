#!/usr/bin/env bash
set -e

LOCATION="$1"
PROCESSOR_ID="$2"
SCHEMA_FILE="$3"

if [ -z "$LOCATION" ] || [ -z "$PROCESSOR_ID" ] || [ -z "$SCHEMA_FILE" ]; then
  echo "Usage: $0 <location> <processor_id> <schema_file>"
  exit 1
fi

echo "Updating dataset schema for processor: ${PROCESSOR_ID}..."
ACCESS_TOKEN=$(gcloud auth print-access-token)

RESPONSE=$(curl -s -X PATCH \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @"${SCHEMA_FILE}" \
  "https://${LOCATION}-documentai.googleapis.com/v1beta3/${PROCESSOR_ID}/dataset/datasetSchema?updateMask=documentSchema")

echo "Response: $RESPONSE"
