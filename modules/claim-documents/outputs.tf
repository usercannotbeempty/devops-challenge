output "bucket_name" {
  description = "Bucket name for the upload backend."
  value       = aws_s3_bucket.documents.id
}

output "bucket_arn" {
  description = "Bucket ARN for scoped workload permissions."
  value       = aws_s3_bucket.documents.arn
}
