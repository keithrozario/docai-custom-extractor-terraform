#!/usr/bin/env bash
set -e

LOCATION="${1:-us}"
PROCESSOR_ID="$2"
DISPLAY_NAME="${3:-v1-custom-extractor}"
BASE_VERSION="${4:-pretrained-foundation-model-v1.5-2025-05-05}"

if [ -z "$PROCESSOR_ID" ]; then
  echo "Usage: $0 <location> <processor_id> [version_display_name] [base_version]"
  echo "Example: $0 us projects/my-project/locations/us/processors/cbb3369272415c5a v1-custom-extractor"
  exit 1
fi

FULL_BASE_VERSION="${PROCESSOR_ID}/processorVersions/${BASE_VERSION}"

echo "Triggering training for processor version '${DISPLAY_NAME}' using base version '${BASE_VERSION}'..."
ACCESS_TOKEN=$(gcloud auth print-access-token)

RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"processorVersion\": {
      \"displayName\": \"${DISPLAY_NAME}\"
    },
    \"baseProcessorVersion\": \"${FULL_BASE_VERSION}\",
    \"foundationModelTuningOptions\": {
      \"trainSteps\": 200
    }
  }" \
  "https://${LOCATION}-documentai.googleapis.com/v1beta3/${PROCESSOR_ID}/processorVersions:train")

echo "Response:"
echo "$RESPONSE"
