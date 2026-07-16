 variable "aws_region" {
        description = "AWS region where the orphaned resources live"
        type        = string
        default     = "us-east-1"
      }

      variable "prefix" {
        description = "Prefix for resource names"
        type        = string
        default     = "lab"
      }

      variable "vpc_cidr" {
        description = "CIDR block of the existing VPC"
        type        = string
        default     = "10.0.0.0/16"
      }

      variable "subnet_cidr" {
        description = "CIDR block of the existing subnet"
        type        = string
        default     = "10.0.1.0/24"
      }