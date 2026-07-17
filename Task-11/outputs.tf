output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_arn
}

 output "logs_bucket_name" {
        description = "The name of the logs bucket"
        value       = module.s3_buckets["logs"].s3_bucket_id
      }
