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

echo "Schema Update Response: $RESPONSE"

echo "Setting default processor version to Foundation Model (pretrained-foundation-model-v1.5-pro-2025-06-20)..."
SET_VERSION_RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "defaultProcessorVersion": "'"${PROCESSOR_ID}"'/processorVersions/pretrained-foundation-model-v1.5-pro-2025-06-20"
  }' \
  "https://${LOCATION}-documentai.googleapis.com/v1/${PROCESSOR_ID}:setDefaultProcessorVersion")

echo "Default Version Response: $SET_VERSION_RESPONSE"
