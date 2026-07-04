variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = ""
}

variable "Name" {
  type = string
  default = ""
}
