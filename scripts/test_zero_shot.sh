#!/usr/bin/env bash
set -e

LOCATION="us"

# Fetch dynamically from terraform if available
if command -v terraform &> /dev/null && [ -d "terraform" ]; then
  PROCESSOR_FULL_ID=$(cd terraform && terraform output -raw processor_id 2>/dev/null || true)
  BUCKET_NAME=$(cd terraform && terraform output -raw storage_bucket_name 2>/dev/null || true)
fi

# Fallback values if terraform outputs are unavailable
if [ -z "$PROCESSOR_FULL_ID" ]; then
  PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "agentspace-krozario")
  PROCESSOR_FULL_ID="projects/${PROJECT_ID}/locations/${LOCATION}/processors/28631a67cae635ce"
fi

if [ -z "$BUCKET_NAME" ]; then
  PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "agentspace-krozario")
  BUCKET_NAME="docai-${PROJECT_ID}-c3c790fd"
fi

TOKEN=$(gcloud auth print-access-token)
ENDPOINT="https://${LOCATION}-documentai.googleapis.com/v1/${PROCESSOR_FULL_ID}:process"

SAMPLE_FILES=(
  "invoice1_acme_corp.pdf"
  "invoice2_apex_logistics.pdf"
  "invoice3_global_supplies.pdf"
  "invoice4_nexus_software.pdf"
  "invoice5_summit_consulting.pdf"
)

echo "=========================================================================="
echo "⚡ Testing Zero-Shot Extraction Across All 5 Sample Invoices"
echo "Processor: ${PROCESSOR_FULL_ID}"
echo "Bucket:    ${BUCKET_NAME}"
echo "=========================================================================="
echo ""

for file in "${SAMPLE_FILES[@]}"; do
  GCS_URI="gs://${BUCKET_NAME}/source-docs/${file}"
  echo "📄 File: ${file}"

  RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
      "gcsDocument": {
        "gcsUri": "'"${GCS_URI}"'",
        "mimeType": "application/pdf"
      }
    }' \
    "${ENDPOINT}")

  if echo "${RESPONSE}" | grep -q '"error":'; then
    echo "  ❌ API Error:"
    echo "${RESPONSE}" | jq .
  else
    echo "${RESPONSE}" | jq -r '
      .document.entities[]? | 
      "  • \(.type): \"\(.mentionText)\" (Confidence: \((.confidence * 100 | round / 100)))\(if .normalizedValue.text then " [Norm: " + .normalizedValue.text + "]" else "" end)"
    '
  fi
  echo "--------------------------------------------------------------------------"
done
