#!/usr/bin/env bash
set -e

PROJECT_ID="agentspace-krozario"
LOCATION="us"
PROCESSOR_ID="a0ec20db13b96b75"
BUCKET_NAME="docai-agentspace-krozario-9d11f433"

TOKEN=$(gcloud auth print-access-token)
ENDPOINT="https://${LOCATION}-documentai.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/processors/${PROCESSOR_ID}:process"

SAMPLE_FILES=(
  "invoice1_acme_corp.pdf"
  "invoice2_apex_logistics.pdf"
  "invoice3_global_supplies.pdf"
  "invoice4_nexus_software.pdf"
  "invoice5_summit_consulting.pdf"
)

echo "=========================================================================="
echo "⚡ Testing Zero-Shot Extraction Across All 5 Sample Invoices"
echo "Processor: projects/${PROJECT_ID}/locations/${LOCATION}/processors/${PROCESSOR_ID}"
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

  echo "${RESPONSE}" | jq -r '
    .document.entities[]? | 
    "  • \(.type): \"\(.mentionText)\" (Confidence: \((.confidence * 100 | round / 100)))\(if .normalizedValue.text then " [Norm: " + .normalizedValue.text + "]" else "" end)"
  '
  echo "--------------------------------------------------------------------------"
done
