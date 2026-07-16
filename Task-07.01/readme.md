=================================================================
LAB-07-AWS: Simplifying Code with Local Values
=================================================================

OVERVIEW
--------
In this lab, you will learn how to use Terraform's `locals` blocks to refactor repetitive code, create computed values, and make your configurations more dynamic. You’ll take an existing configuration with redundant elements and improve it by centralizing common values and creating more maintainable infrastructure code.

This lab uses AWS free-tier–eligible resources to ensure no costs are incurred.

Note: AWS credentials are required for this lab.

LAB PREREQUISITES
-----------------
  Set your AWS credentials as environment variables:
    $ export AWS_ACCESS_KEY_ID="your_access_key"
    $ export AWS_SECRET_ACCESS_KEY="your_secret_key"

  Change to your Terraform working directory:
    $ cd /home/labsuser/code/terraform/aws

  Initalize your working directory:
    $ terraform init

LAB STEPS
---------
1. ADD DATA SOURCES

  Add the following data source to the top of main.tf:

      # Get information about the current region
      data "aws_region" "current" {}

2. CREATE LOCALS BLOCK

  Add the following locals block at the top of main.tf (after the data source):

      locals {
        # Common tags for all resources
        tags = {
          Environment = var.environment
          Project     = "terraform-demo"
          Owner       = "infrastructure-team"
          CostCenter  = "cc-1234"
          Region      = data.aws_region.current.region
          ManagedBy   = "terraform"
        }
        
        # Common name prefix for resources
        name_prefix = "${var.environment}-"
      }

  TIP: Locals are a great way to centralize values that repeat across resources.
  This helps prevent mistakes and ensures consistent naming and tagging standards.

3. REFACTOR RESOURCES

  Replace your existing resource definitions in main.tf with the following:

      resource "aws_vpc" "main" {
        cidr_block           = var.vpc_cidr
        enable_dns_hostnames = true
        enable_dns_support   = true

        tags = {
          Name        = "${local.name_prefix}-vpc-${data.aws_region.current.region}"
          Environment = local.tags.Environment
          Project     = local.tags.Project
          Owner       = local.tags.Owner
          CostCenter  = local.tags.CostCenter
          Region      = local.tags.Region
          ManagedBy   = local.tags.ManagedBy
        }
      }

      resource "aws_subnet" "public_a" {
        vpc_id                  = aws_vpc.main.id
        cidr_block              = "10.0.1.0/24"
        availability_zone       = "us-east-1a"
        map_public_ip_on_launch = true

        tags = merge(local.tags, {
          Name = "${local.name_prefix}-public-subnet-us-east-1a"
          Tier = "public"
        })
      }

      resource "aws_subnet" "public_b" {
        vpc_id                  = aws_vpc.main.id
        cidr_block              = "10.0.2.0/24"
        availability_zone       = "us-east-1b"
        map_public_ip_on_launch = true

        tags = merge(local.tags, {
          Name = "${local.name_prefix}-public-subnet-us-east-1a"
          Tier = "public"
        })
     }


      resource "aws_subnet" "private_a" {
        vpc_id                  = aws_vpc.main.id
        cidr_block              = "10.0.3.0/24"
        availability_zone       = "us-east-1a"
        map_public_ip_on_launch = false

        tags = {
          Name        = "${local.name_prefix}-private-subnet-us-east-1a"
          Environment = local.tags.Environment
          Project     = local.tags.Project
          Owner       = local.tags.Owner
          CostCenter  = local.tags.CostCenter
          Region      = local.tags.Region
          ManagedBy   = local.tags.ManagedBy
          Tier        = "private"
        }
      }

      resource "aws_subnet" "private_b" {
        vpc_id                  = aws_vpc.main.id
        cidr_block              = "10.0.4.0/24"
        availability_zone       = "us-east-1b"
        map_public_ip_on_launch = false

        tags = {
          Name        = "${local.name_prefix}-private-subnet-us-east-1b"
          Environment = local.tags.Environment
          Project     = local.tags.Project
          Owner       = local.tags.Owner
          CostCenter  = local.tags.CostCenter
          Region      = local.tags.Region
          ManagedBy   = local.tags.ManagedBy
          Tier        = "private"
        }
      }

      resource "aws_security_group" "web" {
        name        = "${local.name_prefix}-web-sg"
        description = "Allow web traffic"
        vpc_id      = aws_vpc.main.id

        ingress {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }

        ingress {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }

        egress {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
        tags = local.tags
      }

  LEARNING NOTE: Locals make your code modular by allowing you to compute and reuse values across different resources without duplication.

4. CREATE OUTPUTS FILE

  Add the following to outputs.tf:

      output "vpc_id" {
        description = "The ID of the VPC"
        value       = aws_vpc.main.id
      }

      output "public_subnet_a_id" {
        description = "The ID of public subnet in AZ a"
        value       = aws_subnet.public_a.id
      }

      output "public_subnet_b_id" {
        description = "The ID of public subnet in AZ b"
        value       = aws_subnet.public_b.id
      }

      output "private_subnet_a_id" {
        description = "The ID of private subnet in AZ a"
        value       = aws_subnet.private_a.id
      }

      output "private_subnet_b_id" {
        description = "The ID of private subnet in AZ b"
        value       = aws_subnet.private_b.id
      }

      output "security_group_id" {
        description = "The ID of the security group"
        value       = aws_security_group.web.id
      }

5. APPLY INITIAL CONFIGURATION

  Run the following commands:
    $ terraform init
    $ terraform fmt
    $ terraform validate
    $ terraform plan
    $ terraform apply

  Review the AWS Console:
  - Notice the consistent naming convention from the locals
  - Observe how all resources share common tag values
  - Note how changes to locals affect all resources automatically

6. UPDATE LOCALS AND OBSERVE CHANGES

  Modify the locals block in main.tf:

      locals {
        tags = {
          Environment = var.environment
          Project     = "terraform-improved-demo"  # <-- Changed from "terraform-demo"
          Owner       = "devops-team"              # <-- Changed from "infrastructure-team"
          CostCenter  = "cc-5678"                  # <-- Changed from "cc-1234"
          Region      = data.aws_region.current.region
          ManagedBy   = "terraform"
          Lab         = "lab-07"                   # <-- Added this new tag
        }
        
        name_prefix = "${var.environment}-tf-"     # <-- Added "tf-" to the prefix
      }

  Then, create a new terraform.tfvars file:

      environment = "dev"
      region      = "us-east-1"
      vpc_cidr    = "10.0.0.0/16"

  Apply the configuration again:
    $ terraform plan
    $ terraform apply

  TIP: Locals make global changes simple — you only need to modify one section
  to update every resource consistently across your environment.

7. CLEAN UP

  Destroy all resources when finished:
    $ terraform destroy

SUCCESS CRITERIA
----------------
- Locals block successfully centralizes repeated values
- All resources share consistent tag and naming conventions
- Updating locals updates all dependent resources automatically
- Code is cleaner and easier to maintain
