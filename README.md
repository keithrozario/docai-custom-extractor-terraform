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

## 🎯 Dataset Management, Document Import & Training Workflow

### How Schemas Work in Document AI
In Document AI Workbench:
- **Dataset Schema**: Updated via `update_schema.sh` and visible under **Document AI** $\rightarrow$ **Train / Build** $\rightarrow$ **Edit Schema**.
- **Generative AI Foundation Models**: Custom Extractors automatically utilize Google's **Generative AI Foundation Model** (`pretrained-foundation-model-v1.5-pro`) to perform **Zero-Shot / Few-Shot Extraction** instantly using your schema without needing full custom model training!

### 📄 Sample Documents & Source Reference

> [!NOTE]
> **Source of Demo Documents**:
> The sample invoice PDF documents (`invoice1.pdf` and `invoice2.pdf`) included in this repository and used for testing/demo extraction are publicly available sample test assets sourced from Microsoft Azure Samples:
> - **Invoice 1 (`invoice1.pdf`)**: [Azure Cognitive Services REST API Samples Repository](https://github.com/Azure-Samples/cognitive-services-REST-api-samples/tree/master/curl/form-recognizer/rest-api)
> - **Invoice 2 (`invoice2.pdf`)**: [Azure AI Content Understanding Assets Repository](https://github.com/Azure-Samples/azure-ai-content-understanding-assets)
>
> You can download these sample invoices directly into the `samples/` folder or supply your own business invoices/PDFs for testing.

---

### Step 1: Upload Raw Training / Test Documents to GCS

Upload PDF or image document files into your bucket:

```bash
# Upload sample invoice documents to Cloud Storage
gcloud storage cp samples/*.pdf gs://YOUR_BUCKET_NAME/source-docs/
```

---

### Step 2: Import Documents into Dataset

Import documents into the processor dataset using the `importDocuments` REST endpoint:

```bash
LOCATION="us"
PROCESSOR_ID="projects/YOUR_PROJECT_ID/locations/us/processors/YOUR_PROCESSOR_ID"
BUCKET_NAME="YOUR_BUCKET_NAME"

curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "batchDocumentsImportConfigs": [
      {
        "batchInputConfig": {
          "gcsPrefix": {
            "gcsUriPrefix": "gs://'${BUCKET_NAME}'/source-docs/"
          }
        },
        "autoSplitConfig": {
          "trainingSplitRatio": 0.8
        }
      }
    ]
  }' \
  "https://${LOCATION}-documentai.googleapis.com/v1beta3/${PROCESSOR_ID}/dataset:importDocuments"
```

---

### Step 3: Train / Fine-Tune a Custom Processor Version

If you have annotated documents and wish to fine-tune a dedicated custom `ProcessorVersion`:

```bash
LOCATION="us"
PROCESSOR_ID="projects/YOUR_PROJECT_ID/locations/us/processors/YOUR_PROCESSOR_ID"

curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "processorVersion": {
      "displayName": "v1-custom-extractor"
    },
    "baseProcessorVersion": "'${PROCESSOR_ID}'/processorVersions/pretrained-foundation-model-v1.5-2025-05-05",
    "foundationModelTuningOptions": {
      "trainSteps": 200
    }
  }' \
  "https://${LOCATION}-documentai.googleapis.com/v1beta3/${PROCESSOR_ID}/processorVersions:train"
```

---

### Step 4: Publish / Set Default Processor Version

To set a newly trained version as the active default model version:

```bash
LOCATION="us"
PROCESSOR_ID="projects/YOUR_PROJECT_ID/locations/us/processors/YOUR_PROCESSOR_ID"
VERSION_ID="YOUR_TRAINED_VERSION_ID"

curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "defaultProcessorVersion": "'${PROCESSOR_ID}'/processorVersions/'${VERSION_ID}'"
  }' \
  "https://${LOCATION}-documentai.googleapis.com/v1beta3/${PROCESSOR_ID}:setDefaultProcessorVersion"
```

---

## 🧪 Testing Document Extraction (Inference)

You can process any PDF or image file immediately using the REST API or Python SDK.

### Option A: Testing via cURL REST API

```bash
LOCATION="us"
PROCESSOR_ID="projects/YOUR_PROJECT_ID/locations/us/processors/YOUR_PROCESSOR_ID"
GCS_DOCUMENT_URI="gs://YOUR_BUCKET_NAME/source-docs/invoice1.pdf"

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
        "mentionText": "INV-100",
        "confidence": 0.99998
      },
      {
        "type": "supplier_name",
        "mentionText": "CONTOSO LTD.",
        "confidence": 0.99993
      },
      {
        "type": "invoice_date",
        "mentionText": "11/15/2019",
        "confidence": 0.99998,
        "normalizedValue": {
          "text": "2019-11-15"
        }
      },
      {
        "type": "total_amount",
        "mentionText": "$610.00",
        "confidence": 0.71318,
        "normalizedValue": {
          "text": "610 USD"
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
