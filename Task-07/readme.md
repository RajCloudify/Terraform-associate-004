=================================================================
LAB-06-AWS: Refactoring Terraform Configurations: Making Code Dynamic and Reusable
=================================================================

OVERVIEW
--------
In this lab, you will examine an existing Terraform configuration with hardcoded values and refactor it to be more dynamic and reusable. You'll implement variables, data sources, and string interpolation to create a flexible and maintainable infrastructure definition.

This lab uses AWS free-tier–eligible resources to ensure no costs are incurred.

Note: AWS credentials are required for this lab.

LAB PREREQUISITES
-----------------
  Set your AWS credentials as environment variables:
    $ export AWS_ACCESS_KEY_ID="your_access_key"
    $ export AWS_SECRET_ACCESS_KEY="your_secret_key"

  Change to your Terraform working directory:
    $ cd /home/labsuser/code/terraform/aws

  Apply your existing configuration from LAB-05:
    $ terraform init
    $ terraform apply

LAB STEPS
---------
1. CREATE VARIABLES FILE

  Add the following to variables.tf to replace hardcoded values:

      variable "environment" {
        description = "Environment name for resource naming and tagging"
        type        = string
        default     = "production"
      }

      variable "vpc_cidr" {
        description = "CIDR block for VPC"
        type        = string
        default     = "10.0.0.0/16"
      }

      variable "subnet_cidr" {
        description = "CIDR block for subnet"
        type        = string
        default     = "10.0.1.0/24"
      }

      variable "project_name" {
        description = "Project name for resource tagging"
        type        = string
        default     = "static-infrastructure"
      }

2. ADD DATA SOURCES

  Add the following to the top of main.tf:

      # Retrieve availability zones in the target region
      data "aws_availability_zones" "available" {
        state = "available"
      }

      # Retrieve information about the target region
      data "aws_region" "current" {}

      # Retrieve information about the user and account
      data "aws_caller_identity" "current" {}

3. REFACTOR RESOURCES

  Replace the existing resources in main.tf with this dynamic configuration:

      resource "aws_vpc" "production" {
        cidr_block           = var.vpc_cidr
        enable_dns_hostnames = true
        enable_dns_support   = true

        tags = {
          Name        = "${var.environment}-vpc"
          Environment = var.environment
          Project     = var.project_name
          ManagedBy   = "terraform"
          Region      = data.aws_region.current.name
          AccountID   = data.aws_caller_identity.current.account_id
        }
      }

      resource "aws_subnet" "private" {
        vpc_id                  = aws_vpc.production.id
        cidr_block              = var.subnet_cidr
        availability_zone       = data.aws_availability_zones.available.names[0]
        map_public_ip_on_launch = false

        tags = {
          Name        = "${var.environment}-private-subnet"
          Environment = var.environment
          Project     = var.project_name
          ManagedBy   = "terraform"
          Region      = data.aws_region.current.name
          AZ          = data.aws_availability_zones.available.names[0]
        }
      }

      resource "aws_route_table" "private" {
        vpc_id = aws_vpc.production.id

        tags = {
          Name        = "${var.environment}-route-table"
          Environment = var.environment
          Project     = var.project_name
          ManagedBy   = "terraform"
          Region      = data.aws_region.current.name
        }
      }

4. CREATE OUTPUTS FILE

  Add the following to outputs.tf:

      output "vpc_id" {
        description = "ID of the created VPC"
        value       = aws_vpc.production.id
      }

      output "subnet_id" {
        description = "ID of the created subnet"
        value       = aws_subnet.private.id
      }

      output "availability_zone" {
        description = "Availability zone of the subnet"
        value       = aws_subnet.private.availability_zone
      }

      output "account_info" {
        description = "AWS Account Information"
        value       = "${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"
      }

5. CREATE ENVIRONMENT CONFIGURATION

  Add the following to terraform.tfvars:

      environment  = "development"
      vpc_cidr     = "172.16.0.0/16"
      subnet_cidr  = "172.16.1.0/24"
      project_name = "dynamic-infrastructure"

6. APPLY AND VERIFY

  Initialize and apply the configuration:
    $ terraform init
    $ terraform plan
    $ terraform apply

7. UPDATE TAGS

  Update the value of environment in terraform.tfvars to test dynamic behavior:

      environment  = "testing"
      vpc_cidr     = "172.16.0.0/16"
      subnet_cidr  = "172.16.1.0/24"
      project_name = "dynamic-infrastructure"

8. APPLY THE CHANGES

  Apply again to verify that all affected resources and tags update automatically:
    $ terraform apply

  Confirm the changes with "yes" when prompted.

UNDERSTANDING THE CHANGES
-------------------------
Refactoring the configuration improves flexibility by:

- Using variables for CIDR blocks, environment names, and project tags
- Querying live AWS information through data sources
- Using string interpolation for dynamic names and tags

This makes your code more reusable, consistent, and easier to maintain.

VERIFICATION STEPS
------------------
- Verify that resources are created with dynamic names and tags
- Check that subnet and route table tags reflect account and region data
- Modify terraform.tfvars and confirm updates in AWS Console

CLEAN UP
--------
  Destroy all resources when finished:
    $ terraform destroy

SUCCESS CRITERIA
----------------
- All resources created successfully
- Dynamic naming and tagging applied correctly
- Variables and data sources used throughout
- Configuration reusable across environments
