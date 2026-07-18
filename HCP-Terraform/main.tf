resource "aws_vpc" "hcp" {
  cidr_block         = "10.0.0.0/16"
  enable_dns_support = true
  region             = "us-east-1"
  tags = {
    Name        = "hcp-vpc"
    Environment = "test-hcp"
    ManagedBy   = "Terraform by Raj"
    Developer = "Finally migrated by Raj"
  }
}
