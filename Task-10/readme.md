=================================================================
LAB-AWS-IMPORT-RESOURCES: Importing Existing Resources into Terraform
=================================================================

OVERVIEW
--------

In this lab, you will bring existing, unmanaged AWS resources under Terraform management using both the terraform import CLI command and the import block. You will start with live infrastructure and an empty state file, import each resource, and prove the configuration matches with a clean plan.

This lab picks up exactly where the previous lab (LAB-AWS-REFACTOR-STATE) left off. The VPC, subnet, and security group you orphaned with removed blocks still exist in AWS, but Terraform no longer knows about them. By the end of this lab they are back under Terraform management, and a final terraform destroy cleans up everything the previous lab left behind.

All resources in this lab (VPC, subnet, security group) are free of charge.


LAB PREREQUISITES
-----------------

  - Terraform installed
  - AWS free tier account
  - Completion of the previous lab, with the orphaned resources left in place (see Step 1 if you skipped it)
  - Basic understanding of Terraform and AWS concepts

  Set your AWS credentials as environment variables:
    $ export AWS_ACCESS_KEY_ID="your_access_key"
    $ export AWS_SECRET_ACCESS_KEY="your_secret_key"

  Change to your Terraform working directory:
    $ cd /home/labsuser/code/terraform/aws


ESTIMATED TIME
--------------

30 to 35 minutes


EXISTING CONFIGURATION FILES
----------------------------

You start with three files in your working directory. Unlike previous labs, main.tf starts out empty. The resources already exist in AWS, and your job is to write the configuration that matches them.

The providers.tf file defines the provider and version requirements:

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
        region = var.aws_region
      }

The variables.tf file defines the values the configuration will use. The defaults match the names and CIDRs of the resources the previous lab left behind:

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

The main.tf file contains only a comment:

      # This file starts intentionally empty.
      #
      # The VPC, subnet, and security group created in the previous lab still
      # exist in AWS, but they are no longer tracked in Terraform state.
      # During this lab you will add resource and import blocks here to bring
      # each one back under Terraform management.


LAB STEPS
---------

Step 1: Confirm the orphaned resources still exist

  The previous lab ended with removed blocks that took the VPC, subnet, and security group out of Terraform state while leaving them running in AWS.

  You need the IDs of all three resources to import them. Use the IDs you recorded in Step 8 of the previous lab. If you no longer have them, look them up in the AWS Management Console: in the VPC console, check Your VPCs for lab-vpc and Subnets for lab-subnet, and in the EC2 console, check Security Groups for lab-web-sg.

  If you skipped the previous lab, create the three resources manually in the AWS console before continuing: a VPC named lab-vpc with CIDR 10.0.0.0/16, a subnet named lab-subnet with CIDR 10.0.1.0/24 inside that VPC, and a security group named lab-web-sg with the description "Lab security group" in the same VPC. Add a Name tag to the security group matching its name (the console does not create one for you like it does for the VPC and subnet).


Step 2: Initialize and confirm the state is empty

  Initialize the working directory:
    $ terraform init

  List the resources Terraform is managing:
    $ terraform state list

  The command returns nothing. Real infrastructure exists, but the state file knows about none of it.


Step 3: Write a resource block for the VPC

  Start with the terraform import CLI command. As a reminder, it does not write configuration for you, and it refuses to run until a resource block for the target address exists, so the resource block comes first.

  Add the following resource block to main.tf, describing the VPC exactly as it exists in AWS:

      resource "aws_vpc" "main" {
        cidr_block = var.vpc_cidr

        tags = {
          Name = "${var.prefix}-vpc"
        }
      }

  The address does not need to match the one the previous lab used. What must match is the real resource's attributes, like the CIDR block and the Name tag.


Step 4: Import the VPC with the terraform import command

  Run the import command, substituting the VPC ID you gathered in Step 1:
    $ terraform import aws_vpc.main vpc-xxxxxxxxxxxxxxxxx

  You should see output similar to:

      aws_vpc.main: Importing from ID "vpc-xxxxxxxxxxxxxxxxx"...
      aws_vpc.main: Import prepared!
        Prepared aws_vpc for import
      aws_vpc.main: Refreshing state... [id=vpc-xxxxxxxxxxxxxxxxx]

      Import successful!

      The resources that were imported are shown above. These resources are now in
      your Terraform state and will henceforth be managed by Terraform.

  Confirm the VPC is back in state:
    $ terraform state list

  You should see exactly one address:

      aws_vpc.main


Step 5: Verify the configuration matches reality

  Run a plan:
    $ terraform plan

  You should see:

      No changes. Your infrastructure matches the configuration.

  A clean plan is the proof the import worked. If the plan shows changes, your configuration does not match the real resource. Fix the configuration, not the infrastructure, and plan again until it is clean.


Step 6: Import the subnet with an import block

  Next, use the import block. Instead of running a command per resource, you declare the import in configuration and let a single apply handle several imports at once.

  Add the following to main.tf, substituting your subnet ID from Step 1:

      import {
        to = aws_subnet.app
        id = "subnet-xxxxxxxxxxxxxxxxx"
      }

      resource "aws_subnet" "app" {
        vpc_id     = aws_vpc.main.id
        cidr_block = var.subnet_cidr

        tags = {
          Name = "${var.prefix}-subnet"
        }
      }

  Run a plan:
    $ terraform plan

  The plan now includes an import operation:

      Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.

  Nothing has happened yet, because import blocks perform the import at apply time. Do not apply yet. First, add the security group so a single apply imports both resources.


Step 7: Generate the security group configuration automatically

  For the subnet, you hand-wrote the resource block. For the security group, let Terraform write it for you. Add ONLY an import block to main.tf (no resource block this time), substituting your security group ID from Step 1:

      import {
        to = aws_security_group.main
        id = "sg-xxxxxxxxxxxxxxxxx"
      }

  Now generate configuration for any import target that has no matching resource block:
    $ terraform plan -generate-config-out=generated.tf

  Open generated.tf and review it. Every value is a hardcoded literal (the vpc_id is a raw "vpc-..." string instead of a reference to aws_vpc.main.id), and every settable attribute is listed. Move the resource block into main.tf and clean it up so it looks like this:

      resource "aws_security_group" "main" {
        name        = "${var.prefix}-web-sg"
        description = "Lab security group"
        vpc_id      = aws_vpc.main.id

        tags = {
          Name = "${var.prefix}-web-sg"
        }
      }

  Delete the now-empty generated.tf file, then run a plan to confirm both pending imports are recognized:
    $ terraform plan

      Plan: 2 to import, 0 to add, 0 to change, 0 to destroy.


Step 8: Apply to complete the imports

  Run the apply:
    $ terraform apply

  Type yes when prompted. Terraform imports both resources in one operation:

      Apply complete! Resources: 2 imported, 0 added, 0 changed, 0 destroyed.


Step 9: Verify everything is under management

  List the state one more time:
    $ terraform state list

  You should see all three resources:

      aws_security_group.main
      aws_subnet.app
      aws_vpc.main

  Run a final plan and confirm it comes back clean:
    $ terraform plan

      No changes. Your infrastructure matches the configuration.

  Finally, delete the two import blocks from main.tf. Like moved and removed blocks, they describe a one-time operation and can be removed once applied.


CLEAN UP
--------

Now that Terraform manages the resources again, terraform destroy works.

Destroy the infrastructure:

    $ terraform destroy

Type yes when prompted. You should see:

      Destroy complete! Resources: 3 destroyed.

This removes the resources the previous lab intentionally left behind.


UNDERSTANDING THE TWO IMPORT METHODS
------------------------------------

Importing changes state, never infrastructure. Both methods bind a resource address to a real object, and the object itself is untouched. Terraform does not reconcile your configuration on import, it simply starts comparing the two, which is why a clean plan is the proof an import worked.

The terraform import command is imperative: one command per resource, a hand-written resource block required up front, and no trace left in version control. The import block is declarative: it lives in your configuration, can be reviewed in a pull request, batches many imports into a single apply, and can scaffold configuration with -generate-config-out.

Generated configuration hardcodes every value and includes every settable attribute, so treat it as a draft: replace literals with references and variables, prune what you do not need, and review before applying. Like moved and removed blocks, import blocks describe a one-time operation and can be deleted once applied.


SUCCESS CRITERIA
----------------

You have completed this lab when:
  - terraform state list shows the VPC, subnet, and security group under Terraform management
  - A final terraform plan reports no changes
  - You imported the VPC with the terraform import CLI command and the subnet and security group with import blocks in a single apply
  - You generated configuration for the security group with -generate-config-out and cleaned it up by hand
  - terraform destroy removed all three resources
  - You understand why the resource block must exist before a CLI import, and why a clean plan is the proof that an import worked
