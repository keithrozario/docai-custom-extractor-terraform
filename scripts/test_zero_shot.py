import json
import subprocess
import sys
from google.cloud import documentai_v1 as documentai

def test_zero_shot():
    project_id = "agentspace-krozario"
    location = "us"
    processor_id = "a0ec20db13b96b75"
    bucket_name = "docai-agentspace-krozario-9d11f433"

    sample_files = [
        "invoice1_acme_corp.pdf",
        "invoice2_apex_logistics.pdf",
        "invoice3_global_supplies.pdf",
        "invoice4_nexus_software.pdf",
        "invoice5_summit_consulting.pdf"
    ]

    client = documentai.DocumentProcessorServiceClient()
    processor_path = client.processor_path(project_id, location, processor_id)

    print(f"Testing Zero-Shot Extraction on Processor: {processor_path}\n")

    for file_name in sample_files:
        gcs_uri = f"gs://{bucket_name}/source-docs/{file_name}"
        print(f"📄 Processing Document: {file_name} ({gcs_uri})...")

        request = documentai.ProcessRequest(
            name=processor_path,
            gcs_document=documentai.GcsDocument(
                gcs_uri=gcs_uri,
                mime_type="application/pdf"
            )
        )

        try:
            result = client.process_document(request=request)
            doc = result.document

            print(f"Extracted Entities for {file_name}:")
            for entity in doc.entities:
                norm_val = f" [Normalized: {entity.normalized_value.text}]" if entity.normalized_value and entity.normalized_value.text else ""
                print(f"  • {entity.type_}: '{entity.mention_text}' (Confidence: {entity.confidence:.2%}){norm_val}")
            print("-" * 60)
        except Exception as e:
            print(f"  ❌ Error processing {file_name}: {e}")

if __name__ == "__main__":
    test_zero_shot()
