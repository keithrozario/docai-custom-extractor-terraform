#!/usr/bin/env bash
set -e

LOCATION="${1:-us}"
PROCESSOR_ID="$2"
BUCKET_NAME="$3"

if [ -z "$PROCESSOR_ID" ] || [ -z "$BUCKET_NAME" ]; then
  echo "Usage: $0 <location> <processor_id> <bucket_name>"
  echo "Example: $0 us projects/my-project/locations/us/processors/cbb3369272415c5a docai-bucket-12345"
  exit 1
fi

echo "Importing documents from gs://${BUCKET_NAME}/source-docs/ into dataset..."
ACCESS_TOKEN=$(gcloud auth print-access-token)

RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"batchDocumentsImportConfigs\": [
      {
        \"batchInputConfig\": {
          \"gcsPrefix\": {
            \"gcsUriPrefix\": \"gs://${BUCKET_NAME}/source-docs/\"
          }
        },
        \"autoSplitConfig\": {
          \"trainingSplitRatio\": 0.8
        }
      }
    ]
  }" \
  "https://${LOCATION}-documentai.googleapis.com/v1beta3/${PROCESSOR_ID}/dataset:importDocuments")

echo "Response:"
echo "$RESPONSE"
