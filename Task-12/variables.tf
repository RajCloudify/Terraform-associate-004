variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
variable "policies" {
  description = "Map of IAM policies to create"
  type = map(object({
    description = string
    statements = list(object({
      effect    = string
      actions   = list(string)
      resources = list(string)
    }))
  }))
  default = {
    "s3-read-only" = {
      description = "Allow read-only access to S3"
      statements = [
        {
          effect    = "Allow"
          actions   = ["s3:Get*", "s3:List*"]
          resources = ["*"]
        }
      ]
    }
    "cloudwatch-write" = {
      description = "Allow CloudWatch write access"
      statements = [
        {
          effect    = "Allow"
          actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
          resources = ["*"]
        }
      ]
    }
  }
}
      