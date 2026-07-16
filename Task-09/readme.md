=================================================================
LAB-AWS-REFACTOR-STATE: Refactoring State with the moved and removed Blocks
=================================================================

OVERVIEW
--------

In this lab, you will refactor your Terraform configuration without destroying and recreating live infrastructure. You will first build a small set of AWS networking resources, then see firsthand what happens when you rename a resource without a moved block. You will fix the rename properly with a moved block, practice moving a resource into and back out of a child module, and then use removed blocks in both of their modes: first to destroy a resource you no longer need, and then to hand ownership of the remaining resources off so they stay in place while Terraform stops managing them.

The resources you orphan at the end of this lab are intentionally left in place. The next lab will import those same resources back under Terraform management, so do not delete them if you plan to continue.

All resources in this lab (VPC, subnet, route table, security group) are free of charge, so there is no cost to leave them in AWS between labs.


LAB PREREQUISITES
-----------------
  - Terraform installed
  - AWS free tier account
  - Basic understanding of Terraform and AWS concepts

  Set your AWS credentials as environment variables:
    $ export AWS_ACCESS_KEY_ID="your_access_key"
    $ export AWS_SECRET_ACCESS_KEY="your_secret_key"

  Change to your Terraform working directory:
    $ cd /home/labsuser/code/terraform/aws


ESTIMATED TIME
--------------

40 to 45 minutes


EXISTING CONFIGURATION FILES
----------------------------

You start with two files in your working directory.

The terraform.tf file defines the provider and version requirements:

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
      }

Your main.tf file defines the resources you will refactor:

      resource "aws_vpc" "main" {
        cidr_block = "10.0.0.0/16"

        tags = {
          Name = "lab-vpc"
        }
      }

      resource "aws_subnet" "app" {
        vpc_id     = aws_vpc.main.id
        cidr_block = "10.0.1.0/24"

        tags = {
          Name = "lab-subnet"
        }
      }

      resource "aws_route_table" "main" {
        vpc_id = aws_vpc.main.id

        tags = {
          Name = "lab-rt"
        }
      }

      resource "aws_security_group" "web" {
        name        = "lab-web-sg"
        description = "Lab security group"
        vpc_id      = aws_vpc.main.id

        tags = {
          Name = "lab-web-sg"
        }
      }


LAB STEPS
---------

Step 1: Review and deploy the starting configuration

  Initialize the working directory:
    $ terraform init

  Review the plan, then apply to create the four resources:
    $ terraform plan
    $ terraform apply

  Type yes when prompted. Terraform creates the VPC, subnet, route table, and security group.


Step 2: Confirm the resources are tracked in state

  List the resources Terraform is managing:
    $ terraform state list

  You should see the following four addresses:
      aws_route_table.main
      aws_security_group.web
      aws_subnet.app
      aws_vpc.main


Step 3: See what a rename does WITHOUT a moved block

  Suppose you want to rename the security group resource from "web" to "app" to better reflect its purpose. Before reaching for a moved block, see how Terraform interprets a plain rename.

  In main.tf, change the security group label from "web" to "app":
      resource "aws_security_group" "app" {
        name        = "lab-web-sg"
        description = "Lab security group"
        vpc_id      = aws_vpc.main.id

        tags = {
          Name = "lab-web-sg"
        }
      }

  Run a plan, but DO NOT apply:
    $ terraform plan

  Look closely at the output. Terraform has no idea these are the same resource. It sees a resource named aws_security_group.web that vanished from the configuration and a brand new resource named aws_security_group.app, so it plans to destroy one and create the other:
      Plan: 1 to add, 0 to change, 1 to destroy.

  On a production system this means downtime at best. In this specific case the apply could even fail partway through, because security group names must be unique within a VPC, and the new group uses the same "lab-web-sg" name as the group Terraform is destroying.

  Do not apply this plan. In the next step you will tell Terraform what you actually meant.


Step 4: Rename the resource properly with a moved block

  A moved block tells Terraform that the resource at a new address is the same object as the one at the old address, so it updates the state entry instead of destroying and recreating the resource.

  Leave the renamed resource block in place and add the following moved block to main.tf:
      moved {
        from = aws_security_group.web
        to   = aws_security_group.app
      }

  Run a plan and confirm Terraform now reports a move with zero resources to add, change, or destroy:
    $ terraform plan

  You should see a line similar to:
      aws_security_group.web has moved to aws_security_group.app

  Apply the change:
    $ terraform apply

  Confirm the resource now appears under its new address:
    $ terraform state list

  Once the move is applied, delete the moved block from main.tf. That is safe here because you are the only user of this configuration and you have already applied the move. If this were a shared module, you would keep the moved block in place so other users of the module get the same upgrade path.


Step 5: Move the subnet into a child module

  Renames are not the only refactor a moved block can handle. It can also relocate a resource into a module. Suppose your team decides all networking resources should live in a reusable network module.

  Create the module directory:
    $ mkdir -p modules/network

  Create a new file at modules/network/main.tf with the following content:

      variable "vpc_id" {
        description = "ID of the VPC where the subnet will be created"
        type        = string
      }

      resource "aws_subnet" "app" {
        vpc_id     = var.vpc_id
        cidr_block = "10.0.1.0/24"

        tags = {
          Name = "lab-subnet"
        }
      }

  In main.tf, delete the aws_subnet.app resource block and replace it with a module block and a moved block:

      module "network" {
        source = "./modules/network"

        vpc_id = aws_vpc.main.id
      }

      moved {
        from = aws_subnet.app
        to   = module.network.aws_subnet.app
      }

  Because you added a new module, initialize the working directory again so Terraform installs it:
    $ terraform init

  Run a plan and confirm Terraform reports a move with zero resources to add, change, or destroy:
    $ terraform plan

  You should see a line similar to:
      aws_subnet.app has moved to module.network.aws_subnet.app

  Apply the change, then confirm the subnet now lives at a module address:
    $ terraform apply
    $ terraform state list

  The subnet appears as module.network.aws_subnet.app. The real subnet in AWS was never touched.


Step 6: Move the subnet back to the root module

  Moves work in both directions. The next lab imports these resources into a flat configuration, so move the subnet back to the root module before the handoff.

  First, delete the moved block you added in Step 5. It has been applied and has served its purpose.

  In main.tf, delete the module "network" block and restore the original subnet resource block:

      resource "aws_subnet" "app" {
        vpc_id     = aws_vpc.main.id
        cidr_block = "10.0.1.0/24"

        tags = {
          Name = "lab-subnet"
        }
      }

  Add a moved block pointing in the opposite direction:

      moved {
        from = module.network.aws_subnet.app
        to   = aws_subnet.app
      }

  Run a plan, confirm the move with zero changes, and apply:
    $ terraform plan
    $ terraform apply

  Confirm the subnet is back at its original address:
    $ terraform state list

  Delete this moved block as well, and remove the now unused module directory:
    $ rm -r modules


Step 7: Destroy the route table with a removed block

  A removed block tells Terraform to stop managing a resource. It has two modes, and this step demonstrates the default one: remove the resource from state AND destroy the real infrastructure.

  Your configuration no longer needs the route table, so retire it the configuration-driven way. In main.tf, delete the aws_route_table.main resource block and add the following removed block in its place:

      removed {
        from = aws_route_table.main

        lifecycle {
          destroy = true
        }
      }

  The destroy argument is set to true here for clarity, but true is the default. Run a plan and note the difference from every plan so far in this lab. This one destroys real infrastructure:
    $ terraform plan

  You should see:
      Plan: 0 to add, 0 to change, 1 to destroy.

  Apply the change:
    $ terraform apply

  Confirm the route table is gone from state:
    $ terraform state list

  You should see only three addresses remaining. If you check the VPC console in AWS, the "lab-rt" route table has been deleted. Keep this result in mind, because in Step 9 you will use the same block type with one argument flipped to get the opposite behavior.

  Once the apply completes, delete the removed block from main.tf.


Step 8: Add output blocks to retrieve the resource IDs

  Before you orphan the remaining resources, capture their IDs. You will need them in the next lab to import them back.

  Add the following output blocks to a new outputs.tf file:

      output "vpc_id" {
        value = aws_vpc.main.id
      }

      output "subnet_id" {
        value = aws_subnet.app.id
      }

      output "security_group_id" {
        value = aws_security_group.app.id
      }

  Run a plan and apply to create the outputs:
    $ terraform plan
    $ terraform apply

  In the terminal, you'll see the output values. Write/copy these three IDs down somewhere safe.


Step 9: Orphan the remaining resources with removed blocks

  In Step 7, a removed block destroyed the route table. Setting the lifecycle destroy argument to false changes the behavior entirely: Terraform forgets the resource but leaves it untouched in AWS.

  Delete all three resource blocks from main.tf. Also delete the outputs.tf file, because its outputs reference the resources you are about to remove and would cause an error once those resources leave the configuration. You already recorded the IDs in Step 8.

  Add the following three removed blocks to main.tf in place of the deleted resource blocks:

      removed {
        from = aws_vpc.main

        lifecycle {
          destroy = false
        }
      }

      removed {
        from = aws_subnet.app

        lifecycle {
          destroy = false
        }
      }

      removed {
        from = aws_security_group.app

        lifecycle {
          destroy = false
        }
      }

  Run a plan and confirm Terraform reports the resources will be removed from state with zero resources to destroy:
    $ terraform plan

  Compare this against the plan from Step 7. Same block type, but with destroy set to false the plan shows nothing being destroyed.

  Apply the change:
    $ terraform apply


Step 10: Verify state is empty and the resources still exist

  Confirm Terraform is no longer managing anything:
    $ terraform state list

  This command should return no results.

  Use the AWS Management Console to confirm the resources still exist in AWS. In the VPC console, check Your VPCs for lab-vpc and Subnets for lab-subnet. In the EC2 console, check Security Groups for lab-web-sg. All three resources should still exist, but they are no longer under Terraform management. They are now ready to be imported in the next lab.


CLEAN UP
--------

If you are continuing to LAB-19, stop here and leave the resources in place. You will import and then destroy them in that lab.

If you are not continuing, note that terraform destroy will not remove these resources, because your state file is now empty. The route table was already destroyed by Terraform in Step 7, so only three resources remain. Delete them in the AWS Management Console, in dependency order:

  - In the EC2 console, under Security Groups, delete the lab-web-sg security group
  - In the VPC console, under Subnets, delete the lab-subnet subnet
  - In the VPC console, under Your VPCs, delete the lab-vpc VPC


UNDERSTANDING THE MOVED AND REMOVED BLOCKS
------------------------------------------

The moved block records a change of address for a resource inside Terraform state. It lets you rename a resource, move it into or out of a module, or restructure your configuration without Terraform interpreting the change as a destroy and recreate. The real infrastructure is never touched. You proved this in Step 3: without the moved block, Terraform treated a simple rename as one resource to destroy and another to create, because state tracks resources by address, not by any knowledge of your intent.

Steps 5 and 6 showed that moved blocks handle module refactoring in both directions. Extracting resources into modules is one of the most common refactors on a maturing Terraform codebase, and without moved blocks every extraction would mean destroying and recreating everything the module contains.

Deleting a moved block after it has been applied deserves care. In this lab it was safe, because you are the only user of the configuration and the move was already recorded in your state. In a shared module, deleting a moved block is a breaking change: any consumer who has not yet applied the move would see a plan to destroy the old address instead of moving it. Modules that are shared across teams typically retain their moved blocks indefinitely.

The removed block tells Terraform to stop tracking a resource. This is the configuration-driven replacement for the older terraform state rm command. Its behavior hinges on the lifecycle destroy argument. When destroy is true (the default, as you saw with the route table in Step 7), Terraform removes the resource from state and destroys the real infrastructure, just like deleting the resource block outright. When destroy is false, Terraform forgets the resource but leaves the real infrastructure in place. This is how you hand a resource off between configurations, split a large state file, or transfer ownership between teams without downtime.

Because the orphaned resources are no longer in state, Terraform has no record of them. Any future management must come from importing them back, which is exactly what you will do in the next lab.


SUCCESS CRITERIA
----------------

You have completed this lab when:
  - terraform state list returns no resources
  - The route table was destroyed by the removed block in Step 7
  - The VPC, subnet, and security group still exist in AWS
  - You have recorded the VPC, subnet, and security group IDs for the next lab
  - You understand why renaming a resource without a moved block plans a destroy and create
  - You understand that a removed block destroys by default, and that setting destroy to false forgets a resource without destroying it