variable "project_id" {
  type        = string
  description = "The GCP Project ID where resources will be deployed."
}

variable "region" {
  type        = string
  description = "The GCP region for regional resources (e.g., us-central1)."
  default     = "us-central1"
}

variable "location" {
  type        = string
  description = "The location for Document AI processor ('us' or 'eu')."
  default     = "us"

  validation {
    condition     = contains(["us", "eu"], var.location)
    error_message = "The location must be either 'us' or 'eu' for Document AI Custom Extraction processors."
  }
}

variable "processor_display_name" {
  type        = string
  description = "The display name of the Document AI Custom Extraction Processor."
  default     = "custom-extractor"
}

variable "enable_apis" {
  type        = bool
  description = "Whether to enable required Google Cloud APIs automatically."
  default     = true
}

variable "create_gcs_bucket" {
  type        = bool
  description = "Whether to create a Cloud Storage bucket for document storage and dataset processing."
  default     = true
}

variable "apply_schema" {
  type        = bool
  description = "Whether to automatically apply schema.json to the processor dataset schema."
  default     = true
}

variable "schema_file" {
  type        = string
  description = "Path to the JSON schema file to apply to the Custom Extractor dataset."
  default     = "schema.json"
}

variable "create_dataset" {
  type        = bool
  description = "Whether to initialize/configure the Document AI dataset tied to the processor."
  default     = true
}
