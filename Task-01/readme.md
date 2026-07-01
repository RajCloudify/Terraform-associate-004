=================================================================
LAB-01-AWS: Getting Started with Terraform Configuration with AWS
=================================================================
OVERVIEW
--------
In this lab, you will create your first Terraform configuration for AWS by setting up the required file structure and implementing the AWS provider configuration. You'll learn how to format, validate, and initialize a Terraform working directory.

Note: AWS credentials are not required for this lab as we will only be configuring the provider without creating any resources.

LAB STEPS
---------
1. CHECK TERRAFORM VERSION

  Determine your installed Terraform version by running the following command:
  $ terraform version

  Note this version number as you'll need it for the provider configuration. Since the Terraform Associate 004 certification exam tests on Terraform 1.12, all labs will have 1.12.x installed.

2. CREATE THE PROJECT STRUCTURE

  Create a labs directory and a terraform directory within it that will serve as your workspace for these initial labs:
    $ mkdir -p labs/terraform
    $ cd labs/terraform

  Create the initial configuration files in this directory:
    $ touch main.tf variables.tf providers.tf

  Your directory structure should look like this:
  labs/
  └── terraform/
      ├── main.tf
      ├── providers.tf
      └── variables.tf

  This directory will be your working environment for the upcoming labs as we build our infrastructure incrementally.

3. CONFIGURE THE AWS PROVIDER

  Open providers.tf and add the following configuration (example):

      terraform {
        required_version = ">= 1.12.2"  # Replace with your installed version
        required_providers {
          aws = {
            source = "hashicorp/aws"
            version = "~> 6.0"
          }
        }
      }

      provider "aws" {
        region = "us-east-1"
      }

4. FORMAT THE CONFIGURATION

  Run the following command to ensure consistent formatting:
    $ terraform fmt

  Expected output: If any files were formatted, their names will be listed. If no formatting was needed, there will be no output.

5. INITIALIZE THE WORKING DIRECTORY

  Initialize the working directory to prep the environment and download the provider:
     $ terraform init

  Expected output (example):
  Initializing the backend...
  Initializing provider plugins...
  - Finding hashicorp/aws versions matching "~> 6.0"...
  - Installing hashicorp/aws v6.87.0...
  - Installed hashicorp/aws v6.87.0 (signed by HashiCorp)
  Terraform has created a lock file .terraform.lock.hcl to record the provider
  selections it made above. Include this file in your version control repository
  so that Terraform can guarantee to make the same selections by default when
  you run "terraform init" in the future.

  Terraform has been successfully initialized!

6. VALIDATE THE CONFIGURATION

  Run the validation command to check for syntax errors:
    $ terraform validate

  Expected output:
  Success! The configuration is valid.

7. TEST VERSION CONSTRAINTS

  Experiment with version constraints:

  a) Modify the required_version in your provider configuration to an intentionally high version to see the error example:
    required_version = ">= 99.0.0"

  b) Run the terraform init command:
    $ terraform init

  You should see an error similar to:
  Initializing the backend...
  Error: Unsupported Terraform Core version

  on providers.tf line 2, in terraform:
    required_version = ">= 99.0.0" # Replace with your installed version

  c) Change the version requirement back to your current version, for example:
    required_version = ">= 1.12.2"

  d) Run terraform init again:
    $ terraform init

  Expected output: You should now see success messages indicating proper initialization.

VERIFICATION STEPS
------------------
After completing the lab, verify your work:

1) YOUR DIRECTORY STRUCTURE SHOULD LOOK LIKE THIS:
labs/
└── terraform/
    ├── .terraform/
    ├── .terraform.lock.hcl
    ├── main.tf
    ├── providers.tf
    └── variables.tf

2) VERIFY THE FOLLOWING:
- The .terraform directory exists after initialization
- The .terraform.lock.hcl file has been created
- AWS provider is listed in the lock file
- No error messages are present from the validate command
- All files are properly formatted

CLEAN UP
--------
No clean up is required for this lab as no AWS resources were created.

Success Criteria
- You have created the required file structure
- All Terraform commands (fmt, validate, init) execute successfully
- You observed and understood the version constraint error
- You successfully fixed the version constraint
- The AWS provider is properly initialized
- The .terraform.lock.hcl file is created 