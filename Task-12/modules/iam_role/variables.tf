variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "role_description" {
  description = "Description of the IAM role"
  type        = string
}

variable "trusted_principal" {
  description = "AWS service principal that can assume this role"
  type        = string
}

variable "policy_arns" {
  description = "Map of policy ARNs to attach to the role, keyed by a static name"
  type        = map(string)
  default     = {}
}