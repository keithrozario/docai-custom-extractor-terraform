#!/usr/bin/env bash
set -e

LOCATION="${1:-us}"
PROCESSOR_ID="$2"
VERSION_ID="$3"

if [ -z "$PROCESSOR_ID" ] || [ -z "$VERSION_ID" ]; then
  echo "Usage: $0 <location> <processor_id> <version_id>"
  echo "Example: $0 us projects/my-project/locations/us/processors/cbb3369272415c5a 655bfece7ae37a6c"
  exit 1
fi

FULL_VERSION_PATH="${PROCESSOR_ID}/processorVersions/${VERSION_ID}"

echo "Publishing / Setting default processor version to '${VERSION_ID}'..."
ACCESS_TOKEN=$(gcloud auth print-access-token)

RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"defaultProcessorVersion\": \"${FULL_VERSION_PATH}\"
  }" \
  "https://${LOCATION}-documentai.googleapis.com/v1beta3/${PROCESSOR_ID}:setDefaultProcessorVersion")

echo "Response:"
echo "$RESPONSE"
