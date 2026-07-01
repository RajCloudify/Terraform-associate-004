=================================================================
LAB-02-AWS: Creating Your First AWS Resource
=================================================================

OVERVIEW
--------
In this lab, you will create your first AWS resource using Terraform: a Virtual Private Cloud (VPC). We will build upon the configuration files created in LAB-01, adding resource configuration and implementing the full Terraform workflow. The lab introduces environment variables for AWS credentials, resource blocks, and the essential Terraform commands for resource management.

Note: AWS credentials are required for this lab and must be configured as environment variables.

LAB STEPS
---------
1. NAVIGATE TO YOUR CONFIGURATION DIRECTORY

  Ensure you're in the terraform directory created in LAB-01:
    $ pwd
    /home/labsuser/code/terraform/aws

  If you're in a different directory, change to the Terraform working directory:
    $ cd /home/labsuser/code/terraform/aws

2. CONFIGURE AWS CREDENTIALS

  Set your AWS credentials as environment variables:
    $ export AWS_ACCESS_KEY_ID="your_access_key"
    $ export AWS_SECRET_ACCESS_KEY="your_secret_key"

3. ADD VPC RESOURCE CONFIGURATION

  Open main.tf and add the following VPC configuration (purposely not written in HCL canonical style):

      # Create the primary VPC for workloads
      resource "aws_vpc" "main" {
        cidr_block = "10.0.0.0/16"
        enable_dns_hostnames = true
        enable_dns_support = true

        tags = {
          Name = "terraform-course"
          Environment = "Lab"
          Managed_By = "Terraform"
      }
      }

4. FORMAT AND VALIDATE

  Format your configuration to rewrite it to follow HCL style:
    $ terraform fmt

  Validate the syntax:
    $ terraform validate

5. REVIEW THE PLAN

  Generate and review the execution plan:
    $ terraform plan

  The plan output will show that Terraform intends to create a new VPC with:
  - CIDR block of 10.0.0.0/16
  - DNS features enabled
  - Three tags: Name, Environment, and Managed_By

6. APPLY THE CONFIGURATION

  Apply the configuration to create the VPC:
    $ terraform apply

  Review the proposed changes and type "yes" when prompted to confirm.

7. VERIFY THE RESOURCE

  Verify the VPC creation using the AWS Management Console.

  (Make sure to select the proper region if different.)

8. UPDATE THE VPC RESOURCE

  In the main.tf file, update the VPC configuration:

      # Create the primary VPC for workloads
      resource "aws_vpc" "main" {
        cidr_block           = "192.168.0.0/16" # <-- change IP Address
        enable_dns_hostnames = true
        enable_dns_support   = true

        tags = {
          Name        = "terraform-course"
          Environment = "Lab"
          Managed_By  = "Terraform"
        }
      }

9. RUN A TERRAFORM PLAN (DRY RUN)

  Generate and review the execution plan:
    $ terraform plan

  Since the IP address of a VPC cannot be changed, the plan output will show that Terraform intends to replace the VPC:
  - The VPC with a CIDR block of 10.0.0.0/16 will be destroyed
  - A VPC with a CIDR block of 192.168.0.0/16 will be created

  Expected output:
    aws_vpc.main: Refreshing state... [id=vpc-xxxxx]

    Terraform used the selected providers to generate the following execution plan.
    Resource actions are indicated with the following symbols:
    -/+ destroy and then create replacement

    Terraform will perform the following actions:

      # aws_vpc.main must be replaced

10. APPLY THE CONFIGURATION

  Apply the configuration to create the updated VPC:
    $ terraform apply

  Review the proposed changes and type "yes" when prompted to confirm.

11. UPDATE THE TAGS ON THE VPC

  In the main.tf file, update the VPC configuration:

      # Create the primary VPC for workloads
      resource "aws_vpc" "main" {
        cidr_block           = "192.168.0.0/16"
        enable_dns_hostnames = true
        enable_dns_support   = true

        tags = {
          Name        = "terraform-course"
          Environment = "learning-terraform"  # <-- change tag here
          Managed_By  = "Terraform"
        }
      }

12. RUN A TERRAFORM PLAN (DRY RUN)

  Generate and review the execution plan:
    $ terraform plan

  Since the tags of a VPC can be changed, the plan output will show that Terraform will make an update in-place:
  - The tags of the VPC will be updated

  Expected output:
    aws_vpc.main: Refreshing state... [id=vpc-xxxxxx]

    Terraform used the selected providers to generate the following execution plan.
    Resource actions are indicated with the following symbols:
      ~ update in-place

    Terraform will perform the following actions:

      # aws_vpc.main will be updated in-place

13. APPLY THE CONFIGURATION

  Apply the configuration to update the VPC:
    $ terraform apply

  Review the proposed changes and type "yes" when prompted to confirm.

VERIFICATION STEPS
------------------
After completing the lab, verify your work:

1) CONFIRM THAT:
- The VPC exists in your AWS account with:
  - CIDR block: 192.168.0.0/16
  - DNS hostnames enabled
  - DNS support enabled
  - All specified tags present
- A terraform.tfstate file exists in your directory
- All Terraform commands completed successfully

CLEAN UP
--------
  Destroy resources when finished:
    $ terraform destroy

  Review the proposed changes and type "yes" when prompted to confirm.

SUCCESS CRITERIA
----------------
- AWS credentials are properly configured using environment variables
- The VPC is successfully created with all specified configurations
- All Terraform commands execute without errors
- The terraform.tfstate file accurately reflects your infrastructure
- The resource is successfully destroyed during cleanup
