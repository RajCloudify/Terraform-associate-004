variable "subnet_cidr_blocks" {
  description = "CIDR blocks for subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "region" {
  description = "Region name"
  type = string
  default = "us-east-1"
}

 variable "subnet_config" {
        description = "Map of subnet configurations"
        type        = map(string)
        default = {
          "public"  = "10.0.10.0/24"
          
          "data"    = "10.0.30.0/24"
        }
      }

      variable "subnet_azs" {
        description = "Map of subnet availability zones"
        type        = map(string)
        default = {
          "public"  = "us-east-1a"
          
          "data"    = "us-east-1c"
        }
      }
