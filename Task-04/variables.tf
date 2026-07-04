      variable "public_subnet_cidr" {
        description = "CIDR block for public subnet"
        type        = string
        default     = "10.0.1.0/24"
      }

      variable "private_subnet_cidr" {
        description = "CIDR block for private subnet"
        type        = string
        default     = "10.0.2.0/24"
      }

      variable "availability_zone" {
        description = "Availability zone for subnets"
        type        = string
        default     = "us-east-1a"
      }