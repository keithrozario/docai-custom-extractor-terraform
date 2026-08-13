output "processor_id" {
  description = "The fully qualified resource identifier of the Document AI processor."
  value       = google_document_ai_processor.custom_extractor.id
}

output "processor_name" {
  description = "The resource name of the Document AI processor (projects/PROJECT_NUMBER/locations/LOCATION/processors/PROCESSOR_ID)."
  value       = google_document_ai_processor.custom_extractor.name
}

output "processor_type" {
  description = "The processor type (CUSTOM_EXTRACTION_PROCESSOR)."
  value       = google_document_ai_processor.custom_extractor.type
}

output "processor_location" {
  description = "The location where the processor is hosted."
  value       = google_document_ai_processor.custom_extractor.location
}

output "storage_bucket_name" {
  description = "The name of the GCS bucket created for documents/datasets."
  value       = length(google_storage_bucket.docai_bucket) > 0 ? google_storage_bucket.docai_bucket[0].name : null
}
