mock_provider "aws" {
  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::test-documents"
    }
  }
}

variables {
  name = "test-documents"
}

run "private_encrypted_versioned_documents" {
  command = apply

  assert {
    condition     = aws_s3_bucket_public_access_block.documents.block_public_acls && aws_s3_bucket_public_access_block.documents.block_public_policy && aws_s3_bucket_public_access_block.documents.ignore_public_acls && aws_s3_bucket_public_access_block.documents.restrict_public_buckets
    error_message = "Public access must be blocked."
  }
  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.documents.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "Documents must be encrypted by default."
  }
  assert {
    condition     = aws_s3_bucket_versioning.documents.versioning_configuration[0].status == "Enabled" && !aws_s3_bucket.documents.force_destroy
    error_message = "Keep object versions and disallow forced deletion of a nonempty bucket."
  }
  assert {
    condition     = jsondecode(aws_s3_bucket_policy.documents.policy).Statement[0].Condition.Bool["aws:SecureTransport"] == "false"
    error_message = "Non-TLS requests must be denied."
  }
}
