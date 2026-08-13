# project_id is optional and defaults to the active project configured in gcloud
# project_id             = ""

region                 = "us-central1"
location               = "us"
processor_display_name = "docai-custom-extractor"
create_gcs_bucket      = true
enable_apis            = true
apply_schema           = true
schema_file            = "schema.json"
create_dataset         = true
