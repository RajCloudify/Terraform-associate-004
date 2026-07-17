variable "environment" {
  description = "Environment name used to prefix resources"
  type        = string
  default     = "dev"
}

 variable "region" {
        description = "AWS region for the VPC availability zones"
        type        = string
        default     = "us-east-1"
      }


      variable "vpc_cidr" {
        description = "CIDR block for the VPC"
        type        = string
        default     = "10.0.0.0/16"
      }
    
     variable "bucket_names" {
        description = "Names for the additional S3 buckets"
        type        = list(string)
        default     = ["logs", "images"]
      }