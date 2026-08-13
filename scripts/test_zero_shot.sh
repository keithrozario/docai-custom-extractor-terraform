#!/usr/bin/env bash
set -e

PROJECT_ID="agentspace-krozario"
LOCATION="us"

# Fetch dynamically from terraform if available, or fallback
if command -v terraform &> /dev/null && [ -d "terraform" ]; then
  PROCESSOR_FULL_ID=$(cd terraform && terraform output -raw processor_id 2>/dev/null || true)
  BUCKET_NAME=$(cd terraform && terraform output -raw storage_bucket_name 2>/dev/null || true)
fi

if [ -n "$PROCESSOR_FULL_ID" ]; then
  PROCESSOR_ID="${PROCESSOR_FULL_ID##*/}"
else
  PROCESSOR_ID="28631a67cae635ce"
fi

if [ -z "$BUCKET_NAME" ]; then
  BUCKET_NAME="docai-agentspace-krozario-c3c790fd"
fi

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
