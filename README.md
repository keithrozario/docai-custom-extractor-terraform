# Document AI Custom Extractor - Terraform & Workbench Guide

This project provides an automated Terraform setup to provision a **Google Cloud Document AI Custom Extractor** (`CUSTOM_EXTRACTION_PROCESSOR`), configure its **Cloud Storage Bucket**, programmatically define its **Extraction Entity Schema** (`schema.json`), initialize its **Document AI Dataset**, and run end-to-end training and document extraction.

---

## 🏗️ Architecture & Resources Provisioned

- **GCP Service APIs**: `documentai.googleapis.com`, `storage.googleapis.com`
- **Document AI Processor**: `CUSTOM_EXTRACTION_PROCESSOR` (`location = "us"` or `"eu"`)
- **Cloud Storage Bucket**: `docai-{project_id}-{random_id}` for dataset storage, raw documents, and exported annotations.
- **Dataset Initialization**: Binds processor dataset storage to `gs://docai-{project_id}-{random_id}/dataset/`.
- **Dataset Schema Auto-Provisioning**: Programmatically updates `datasetSchema` with custom extraction fields via Document AI `v1beta3` REST API.

---

## 📋 Prerequisites

Before starting, ensure you have the following installed and configured:

1. **GCP Account & Project** with billing enabled.
2. **Terraform** (`>= 1.0.0`): Install via `brew install terraform` or Linux package manager.
3. **Google Cloud SDK (`gcloud` CLI)**: Installed and authenticated.
4. **GCP IAM Permissions**: Roles required on the GCP project:
   - `roles/documentai.editor` or `roles/owner`
   - `roles/storage.admin`
   - `roles/serviceusage.serviceUsageAdmin`

### Authentication Setup
Run the following commands to authenticate `gcloud` and generate Application Default Credentials (ADC) for Terraform:

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

---

## 🧩 Understanding the Custom Extractor Schema (`schema.json`)

The `schema.json` file dictates **which entities/fields** Document AI will extract from incoming documents.

### Schema Structure & Schema Syntax

```json
{
  "documentSchema": {
    "entityTypes": [
      {
        "name": "custom_extraction_document_type",
        "baseTypes": ["document"],
        "properties": [
          {
            "name": "invoice_number",
            "displayName": "Invoice Number",
            "valueType": "string",
            "occurrenceType": "OPTIONAL_ONCE"
          },
          {
            "name": "total_amount",
            "displayName": "Total Amount",
            "valueType": "money",
            "occurrenceType": "OPTIONAL_ONCE"
          },
          {
            "name": "invoice_date",
            "displayName": "Invoice Date",
            "valueType": "datetime",
            "occurrenceType": "OPTIONAL_ONCE"
          },
          {
            "name": "supplier_name",
            "displayName": "Supplier Name",
            "valueType": "string",
            "occurrenceType": "OPTIONAL_ONCE"
          }
        ]
      }
    ]
  }
}
```

### Property Parameter Reference

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `name` | `string` | **Programmatic key** returned in API responses (e.g., `invoice_number`). Use lower_snake_case. |
| `displayName` | `string` | **Human-readable label** displayed in the Document AI Google Cloud Console UI. |
| `valueType` | `string` | Field data type. Options: `string`, `money`, `datetime`, `integer`, `float`, `boolean`, `address`. |
| `occurrenceType` | `string` | Occurrence constraint:<br>• `OPTIONAL_ONCE`: Field occurs 0 or 1 time.<br>• `OPTIONAL_MULTIPLE`: Field occurs 0 or more times.<br>• `REQUIRED_ONCE`: Field must appear once.<br>• `REQUIRED_MULTIPLE`: Field must appear 1 or more times. |

### Adding Nested Line Items / Table Schema
To add repeated table rows or line items, add a property with `valueType: "object"` and define child `properties`:

```json
{
  "name": "line_item",
  "displayName": "Line Item",
  "valueType": "object",
  "occurrenceType": "OPTIONAL_MULTIPLE",
  "properties": [
    {
      "name": "item_description",
      "displayName": "Description",
      "valueType": "string",
      "occurrenceType": "OPTIONAL_ONCE"
    },
    {
      "name": "item_amount",
      "displayName": "Amount",
      "valueType": "money",
      "occurrenceType": "OPTIONAL_ONCE"
    }
  ]
}
```

---

## 🚀 Spinning Up From Scratch

### Step 1: Clone or Prepare Configuration
Create your local environment configuration file from the example template:

```bash
cp terraform.tfvars.example terraform.tfvars
```

### Step 2: Configure `terraform.tfvars`
Edit `terraform.tfvars` to set your target GCP Project ID and settings:

```hcl
project_id             = "your-gcp-project-id"
region                 = "us-central1"
location               = "us"
processor_display_name = "docai-custom-extractor"
create_gcs_bucket      = true
enable_apis            = true
apply_schema           = true
schema_file            = "schema.json"
create_dataset         = true
```

### Step 3: Deploy with Terraform

```bash
# Initialize Terraform providers
terraform init

# Review execution plan
terraform plan

# Apply changes to GCP
terraform apply -auto-approve
```

Upon completion, Terraform outputs key details:
```text
Outputs:

processor_id        = "projects/YOUR_PROJECT_ID/locations/us/processors/cbb3369272415c5a"
processor_location  = "us"
processor_name      = "cbb3369272415c5a"
processor_type      = "CUSTOM_EXTRACTION_PROCESSOR"
storage_bucket_name = "docai-YOUR_PROJECT_ID-a6dfe5e7"
```

---

## ⚡ Zero-Shot Extraction Capability

Google Cloud Document AI Custom Extractors natively leverage Google's **Generative AI Foundation Models** (`pretrained-foundation-model-v1.5-pro` / `v1.5`).

### Key Benefits of Zero-Shot Extraction:
- **No Model Training Required**: Extraction works **instantly** out-of-the-box once `schema.json` is applied.
- **No Bounding Box Annotations Needed**: You do NOT need labeled training documents or manual annotations to start extracting entities.
- **High Precision**: Understands contextual document semantics and extracts text, amounts, dates, and nested line item tables directly based on field names and display names in `schema.json`.

---

## 🚀 Instant Zero-Shot Workflow (Recommended)

To run instant zero-shot document extraction without fine-tuning:

1. **Deploy Infrastructure**:
   ```bash
   terraform apply -auto-approve
   ```
   This automatically provisions the processor, Cloud Storage bucket, dataset, applies `schema.json`, and uploads sample documents to `gs://<bucket_name>/source-docs/`.

2. **Process Any Document Immediately**:
   Call the `:process` endpoint directly via cURL or Python SDK (see [Testing Document Extraction](#-testing-document-extraction-inference)). Entities defined in `schema.json` will be extracted with high confidence immediately!

---

## 🎯 (Optional) Dataset Management & Fine-Tuning Workflow

> [!NOTE]
> **When is Fine-Tuning Needed?**
> Custom model fine-tuning (`train_version.sh`) is **100% optional**. You only need to fine-tune if you have complex edge-case documents that require custom model weight adjustments beyond the standard Foundation Model capabilities.
>
> **Prerequisite for Fine-Tuning**: Fine-tuning requires at least **1 or more documents with ground-truth human bounding-box annotations** added via the Document AI Google Cloud Console Workbench UI.

### Step 1: Upload Raw Documents (Automated in Terraform)

> All sample PDFs located in the `samples/` folder are **automatically uploaded** to `gs://<bucket_name>/source-docs/` during `terraform apply`.

---

### Step 2: Import Documents into Dataset (`import_documents.sh`)

Import uploaded documents into the Document AI Dataset using [import_documents.sh](file:///home/keith_krozario_altostrat_com/projects/docAi-test/import_documents.sh):

```bash
./import_documents.sh <location> <processor_id> <bucket_name>

# Example:
./import_documents.sh us projects/YOUR_PROJECT_ID/locations/us/processors/YOUR_PROCESSOR_ID docai-YOUR_PROJECT_ID-a6dfe5e7
```

---

### Step 3: (Optional) Fine-Tune Custom Processor Version (`train_version.sh`)

If you have annotated documents in your dataset and wish to train a dedicated custom `ProcessorVersion`, execute [train_version.sh](file:///home/keith_krozario_altostrat_com/projects/docAi-test/train_version.sh):

```bash
./train_version.sh <location> <processor_id> [version_display_name] [base_version]

# Example:
./train_version.sh us projects/YOUR_PROJECT_ID/locations/us/processors/YOUR_PROCESSOR_ID v1-custom-extractor
```

---

### Step 4: (Optional) Publish Default Processor Version (`publish_version.sh`)

To set a newly fine-tuned processor version as the active default model version, execute [publish_version.sh](file:///home/keith_krozario_altostrat_com/projects/docAi-test/publish_version.sh):

```bash
./publish_version.sh <location> <processor_id> <version_id>

# Example:
./publish_version.sh us projects/YOUR_PROJECT_ID/locations/us/processors/YOUR_PROCESSOR_ID 655bfece7ae37a6c
```

---

## 🧪 Testing Document Extraction (Inference)

You can process any PDF or image file immediately using the REST API or Python SDK.

### Option A: Testing via cURL REST API

```bash
LOCATION="us"
PROCESSOR_ID="projects/YOUR_PROJECT_ID/locations/us/processors/YOUR_PROCESSOR_ID"
GCS_DOCUMENT_URI="gs://YOUR_BUCKET_NAME/source-docs/invoice1_acme_corp.pdf"

curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "gcsDocument": {
      "gcsUri": "'${GCS_DOCUMENT_URI}'",
      "mimeType": "application/pdf"
    }
  }' \
  "https://${LOCATION}-documentai.googleapis.com/v1/${PROCESSOR_ID}:process"
```

#### Sample Extracted Response
```json
{
  "document": {
    "entities": [
      {
        "type": "invoice_number",
        "mentionText": "INV-2026-001",
        "confidence": 0.99999
      },
      {
        "type": "supplier_name",
        "mentionText": "Acme Industrial Solutions",
        "confidence": 0.99998
      },
      {
        "type": "invoice_date",
        "mentionText": "2026-03-15",
        "confidence": 0.99998,
        "normalizedValue": {
          "text": "2026-03-15"
        }
      },
      {
        "type": "total_amount",
        "mentionText": "$1,250.00",
        "confidence": 0.74709,
        "normalizedValue": {
          "text": "1250 USD"
        }
      }
    ]
  }
}
```

### Option B: Testing via Python SDK

```python
from google.cloud import documentai_v1 as documentai

def process_document(project_id: str, location: str, processor_id: str, gcs_uri: str):
    client = documentai.DocumentProcessorServiceClient()
    name = client.processor_path(project_id, location, processor_id)

    request = documentai.ProcessRequest(
        name=name,
        gcs_document=documentai.GcsDocument(
            gcs_uri=gcs_uri,
            mime_type="application/pdf"
        )
    )

    result = client.process_document(request=request)
    document = result.document

    print(f"Extracted Text Snippet: {document.text[:100]}...\n")
    print("Extracted Entities:")
    for entity in document.entities:
        print(f" - {entity.type_}: '{entity.mention_text}' (Confidence: {entity.confidence:.2%})")

# Usage:
# process_document("YOUR_PROJECT_ID", "us", "YOUR_PROCESSOR_ID", "gs://YOUR_BUCKET_NAME/source-docs/invoice1.pdf")
```

---

## 🧹 Destroying Resources

To remove all provisioned GCP infrastructure:

```bash
terraform destroy -auto-approve
```
