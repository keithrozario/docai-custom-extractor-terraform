# Fetch current GCP client configuration (active gcloud project if var.project_id is empty/null)
data "google_client_config" "current" {}

locals {
  project_id = (var.project_id != null && var.project_id != "") ? var.project_id : data.google_client_config.current.project
}

# Enable required Google Cloud Service APIs
resource "google_project_service" "documentai" {
  count              = var.enable_apis ? 1 : 0
  project            = local.project_id
  service            = "documentai.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "storage" {
  count              = var.enable_apis ? 1 : 0
  project            = local.project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

# Create the Document AI Custom Extraction Processor
resource "google_document_ai_processor" "custom_extractor" {
  location     = var.location
  display_name = var.processor_display_name
  type         = "CUSTOM_EXTRACTION_PROCESSOR"

  depends_on = [
    google_project_service.documentai
  ]
}

# Helper resource to generate a random string for unique bucket naming
resource "random_id" "bucket_prefix" {
  byte_length = 4
}

# Optional Cloud Storage Bucket for document input/output and dataset management
resource "google_storage_bucket" "docai_bucket" {
  count                       = var.create_gcs_bucket ? 1 : 0
  name                        = "docai-${local.project_id}-${random_id.bucket_prefix.hex}"
  location                    = var.location == "us" ? "US" : (var.location == "eu" ? "EU" : var.region)
  force_destroy               = true
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [
    google_project_service.storage
  ]
}

# Apply Custom Extraction Schema to the Processor
resource "null_resource" "update_processor_schema" {
  count = var.apply_schema ? 1 : 0

  triggers = {
    schema_hash  = filemd5("${path.module}/${var.schema_file}")
    processor_id = google_document_ai_processor.custom_extractor.id
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/../scripts/update_schema.sh '${var.location}' '${google_document_ai_processor.custom_extractor.id}' '${path.module}/${var.schema_file}'"
  }

  depends_on = [
    google_document_ai_processor.custom_extractor,
    null_resource.initialize_processor_dataset
  ]
}

# Initialize/Configure Dataset for the Processor
resource "null_resource" "initialize_processor_dataset" {
  count = (var.create_dataset && var.create_gcs_bucket) ? 1 : 0

  triggers = {
    processor_id = google_document_ai_processor.custom_extractor.id
    bucket_name  = google_storage_bucket.docai_bucket[0].name
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/../scripts/update_dataset.sh '${var.location}' '${google_document_ai_processor.custom_extractor.id}' '${google_storage_bucket.docai_bucket[0].name}'"
  }

  depends_on = [
    google_document_ai_processor.custom_extractor,
    google_storage_bucket.docai_bucket
  ]
}

# Upload Sample Documents to Cloud Storage (Step 1)
resource "google_storage_bucket_object" "sample_documents" {
  for_each = var.create_gcs_bucket ? fileset("${path.module}/../samples", "*.pdf") : []

  name   = "source-docs/${each.value}"
  bucket = google_storage_bucket.docai_bucket[0].name
  source = "${path.module}/../samples/${each.value}"

  depends_on = [
    google_storage_bucket.docai_bucket
  ]
}
