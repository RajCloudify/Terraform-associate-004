=================================================================
LAB-04-AWS: Managing Multiple Resources and Dependencies
=================================================================

OVERVIEW
--------
In this lab, you will expand your VPC configuration by adding multiple interconnected resources. You'll learn how Terraform manages dependencies between resources and how to structure more complex configurations. We'll create subnets, route tables, and security groups, all of which are free resources in AWS.

Note: AWS credentials are required for this lab and must be configured as environment variables.
 
LAB PREREQUISITES
-----------------
  Set your AWS credentials as environment variables:
    $ export AWS_ACCESS_KEY_ID="your_access_key"
    $ export AWS_SECRET_ACCESS_KEY="your_secret_key"

  Change to your Terraform working directory:
    $ cd /home/labsuser/code/terraform/aws

  Apply your existing configuration from LAB-03:
    $ terraform init
    $ terraform apply

LAB STEPS
---------
1. ADD NEW VARIABLE DEFINITIONS

  Add the following to variables.tf:

      variable "public_subnet_cidr" {
        description = "CIDR block for public subnet"
        type        = string
        default     = "10.0.1.0/24"
      }

      variable "private_subnet_cidr" {
        description = "CIDR block for private subnet"
        type        = string
        default     = "10.0.2.0/24"
      }

      variable "availability_zone" {
        description = "Availability zone for subnets"
        type        = string
        default     = "us-east-1a"
      }

2. CREATE SUBNETS

  Add the following to main.tf:

      resource "aws_subnet" "public" {
        vpc_id                  = aws_vpc.main.id
        cidr_block              = var.public_subnet_cidr
        availability_zone       = var.availability_zone
        map_public_ip_on_launch = true

        tags = {
          Name        = "public-subnet"
          Environment = var.environment
        }
      }

      resource "aws_subnet" "private" {
        vpc_id            = aws_vpc.main.id
        cidr_block        = var.private_subnet_cidr
        availability_zone = var.availability_zone

        tags = {
          Name        = "private-subnet"
          Environment = var.environment
        }
      }

  (Note how we use resource references to dynamically connect subnets to the VPC.)

3. CREATE ROUTE TABLE

  Add this block to main.tf:

      resource "aws_route_table" "main" {
        vpc_id = aws_vpc.main.id

        tags = {
          Name        = "main-route-table"
          Environment = var.environment
        }
      }

4. CREATE ROUTE TABLE ASSOCIATIONS

  Add the following to main.tf:

      resource "aws_route_table_association" "public" {
        subnet_id      = aws_subnet.public.id
        route_table_id = aws_route_table.main.id
      }

      resource "aws_route_table_association" "private" {
        subnet_id      = aws_subnet.private.id
        route_table_id = aws_route_table.main.id
      }

  Terraform knows that the VPC, subnets, and route table must exist before these associations
  are created. This is called an implicit dependency.

5. CREATE SECURITY GROUP

  Add a simple example security group and rules to main.tf:

    resource "aws_security_group" "example" {
      name        = "example-security-group"
      description = "Example security group for our VPC"
      vpc_id      = aws_vpc.main.id

      revoke_rules_on_delete = true

      tags = {
        Name        = "example-security-group"
        Environment = var.environment
      }
    }

    resource "aws_security_group_rule" "allow_http" {
      type              = "ingress"
      from_port         = 80
      to_port           = 80
      protocol          = "tcp"
      cidr_blocks       = ["0.0.0.0/0"]
      security_group_id = aws_security_group.example.id
      description       = "Allow HTTP (80)"
    }

    resource "aws_security_group_rule" "allow_https" {
      type              = "ingress"
      from_port         = 443
      to_port           = 443
      protocol          = "tcp"
      cidr_blocks       = ["0.0.0.0/0"]
      security_group_id = aws_security_group.example.id
      description       = "Allow HTTPS (443)"
    }

    resource "aws_security_group_rule" "egress_all" {
      type              = "egress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = ["0.0.0.0/0"]
      security_group_id = aws_security_group.example.id
      description       = "Allow all outbound traffic"
    }

6. ADD NEW OUTPUTS

  Add the following to outputs.tf:

      output "public_subnet_id" {
        description = "ID of the public subnet"
        value       = aws_subnet.public.id
      }

      output "private_subnet_id" {
        description = "ID of the private subnet"
        value       = aws_subnet.private.id
      }

      output "route_table_id" {
        description = "ID of the main route table"
        value       = aws_route_table.main.id
      }

      output "security_group_id" {
        description = "ID of the security group"
        value       = aws_security_group.example.id
      }

7. UPDATE TERRAFORM.TFVARS

  Add subnet values to terraform.tfvars:

      public_subnet_cidr  = "10.0.1.0/24"
      private_subnet_cidr = "10.0.2.0/24"
      availability_zone   = us-east-1a

  Run:
    $ terraform fmt
    $ terraform validate
    $ terraform plan


  Notice that you get an error, stating that variables are not allowed here. This is because the value for `availability_zone` in our `terraform.tfvars` file was not added as a string - it's missing double-quotes ("). You probably got an error like this (see how the error message gives you the file name (`terraform.tfvars`), the line where the error was caught (`line 6`), the code that is causing the error (`availability_zone = us-east-1a`), and the error message at the bottom):

  ------------------
  $ terraform plan
  ╷
  │ Error: Variables not allowed
  │ 
  │   on terraform.tfvars line 6:
  │    6: availability_zone   = us-east-1a
  │ 
  │ Variables may not be used here.
  ------------------

  This proves that `terraform validate` doesn't always catch everything, and you might find errrors once you get to a `terraform plan` or `terraform apply` that wasn't caught by `terraform validate`.

  Put double-quotes around the value for `availability_zone` in our terraform.tfvars file as shown below:

  availability_zone = "us-east-1a"

    Run again:
      $ terraform plan
      $ terraform apply

    Confirm with "yes".

UNDERSTANDING RESOURCE DEPENDENCIES
-----------------------------------
Terraform automatically determines the correct creation order:
- The VPC must exist before subnets
- Subnets must exist before route table associations
- The VPC must exist before the security group

This happens through implicit dependencies via resource references.

VERIFICATION STEPS
------------------
- Verify subnets, route table, and associations in the AWS console
- Confirm the security group and its rules
- Check terraform outputs for resource IDs

CLEAN UP
--------
  Destroy resources when finished:
    $ terraform destroy

SUCCESS CRITERIA
----------------
- All resources created successfully
- Dependencies maintained automatically
- Tags applied correctly
- Security group rules match configuration
- Resource IDs displayed in outputs
