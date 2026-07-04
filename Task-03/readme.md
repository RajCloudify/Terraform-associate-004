=================================================================
LAB-03-AWS: Working with Variables and Outputs
=================================================================

OVERVIEW
--------
In this lab, you will enhance your existing VPC configuration by implementing variables and outputs. You'll learn how variables work, how different variable definitions take precedence, and how to use output values to display resource information. We'll build this incrementally to understand how each change affects our configuration.

Note: AWS credentials are required for this lab and must be configured as environment variables.

LAB PREREQUISITES
-----------------
  Set your AWS credentials as environment variables:
    $ export AWS_ACCESS_KEY_ID="your_access_key"
    $ export AWS_SECRET_ACCESS_KEY="your_secret_key"

  Change to your Terraform working directory:
    $ cd /home/labsuser/code/terraform/aws

  Apply your existing configuration from LAB-02:
    $ terraform init
    $ terraform apply

LAB STEPS
---------
1. REVIEW CURRENT CONFIGURATION AND CONFIGURE AWS CREDENTIALS

  Review your current main.tf file from the previous lab:

      resource "aws_vpc" "main" {
        cidr_block           = "192.168.0.0/16"
        enable_dns_hostnames = true
        enable_dns_support   = true

        tags = {
          Name        = "terraform-course"
          Environment = "learning-terraform"
          Managed_By  = "Terraform"
        }
      }

2. ADD VARIABLE DEFINITIONS

  Create or update variables.tf with the following content:

      variable "vpc_cidr" {
        description = "CIDR block for VPC"
        type        = string
        default     = "192.168.0.0/16"
      }

      variable "environment" {
        description = "Environment name for tagging"
        type        = string
        default     = "learning-terraform"
      }

  Run a plan to confirm no changes yet:
    $ terraform plan

3. UPDATE MAIN CONFIGURATION TO USE VARIABLES

  Modify main.tf to use the variables:

      resource "aws_vpc" "main" {
        cidr_block           = var.vpc_cidr
        enable_dns_hostnames = true
        enable_dns_support   = true

        tags = {
          Name        = "terraform-course"
          Environment = var.environment
          Managed_By  = "Terraform"
        }
      }

  Run:
    $ terraform plan

  (No changes expected because defaults match current configuration.)

4. CREATE TERRAFORM.TFVARS

  Create a terraform.tfvars file:
    $ touch terraform.tfvars

  Add values to override defaults:

      vpc_cidr    = "10.0.0.0/16"
      environment = "development"

  Run:
    $ terraform plan

  You should see a destroy/recreate plan because of the new CIDR and tag.

5. UPDATE PROVIDER WITH DEFAULT TAGS

  Update providers.tf:

      terraform {
        required_version = ">= 1.12.2"
        required_providers {
          aws = {
            source  = "hashicorp/aws"
            version = "~> 6.0"
          }
        }
      }

      provider "aws" {
        region = "us-east-1"
        default_tags {
          tags = {
            Managed_By = "Terraform"
            Project    = "Terraform Training"
          }
        }
      }

  Remove Managed_By from main.tf tags:

      resource "aws_vpc" "main" {
        cidr_block           = var.vpc_cidr
        enable_dns_hostnames = true
        enable_dns_support   = true

        tags = {
          Name        = "terraform-course"
          Environment = var.environment
        }
      }

  Run and apply:
    $ terraform plan
    $ terraform apply

6. ADD OUTPUT DEFINITIONS

  Create outputs.tf:

      output "vpc_id" {
        description = "ID of the created VPC"
        value       = aws_vpc.main.id
      }

      output "vpc_arn" {
        description = "ARN of the created VPC"
        value       = aws_vpc.main.arn
      }

      output "vpc_cidr" {
        description = "CIDR block of the created VPC"
        value       = aws_vpc.main.cidr_block
      }

  Apply again:
    $ terraform apply

  Outputs will display in the terminal.

7. EXPERIMENT WITH VARIABLE PRECEDENCE

  Create testing.tfvars:

      vpc_cidr    = "172.16.0.0/16"
      environment = "testing"

  Run with var-file:
    $ terraform plan -var-file="testing.tfvars"

  Observe that these values override all others.

8. DELETE THE TESTING FILE

  Delete testing.tfvars, then run:
    $ terraform plan

  No changes should be required.

VERIFICATION STEPS
------------------
- The plan output matches expectations
- You understand variable precedence
- Resource attributes reflect correct values
- Tags are applied as expected
- Outputs display correct information

CLEAN UP
--------
  Destroy resources when finished:
    $ terraform destroy

SUCCESS CRITERIA
----------------
- Variables are correctly defined and override defaults
- Provider-level default tags are applied
- Outputs display key resource information
- Variable precedence is understood
