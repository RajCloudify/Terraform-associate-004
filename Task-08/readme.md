=================================================================
LAB-08-AWS: Scaling Resources with Count and For_Each
=================================================================

OVERVIEW
--------
In this lab, you will take a Terraform configuration containing individually defined, repetitive resources and refactor it using the count and for_each meta-arguments. You'll first consolidate duplicate subnet and security group resources using count, then refactor again to use for_each. Finally, you'll modify both approaches to observe a critical difference: how each handles resource removal.

The lab uses AWS free-tier resources to ensure no costs are incurred.

Note: AWS credentials are required for this lab.

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

  Apply your existing configuration:
    $ terraform init
    $ terraform apply

ESTIMATED TIME
--------------
  60 minutes

EXISTING CONFIGURATION FILES
-----------------------------
  The lab directory contains the following starter files:

    - main.tf
    - variables.tf
    - providers.tf

  Examine main.tf and notice:
    - Three individually defined subnets (subnet_1, subnet_2, subnet_3)
    - Three individually defined security groups (web, app, db)
    - Hardcoded CIDR blocks, availability zones, and ports
    - Repetitive resource blocks that differ only in a few values

  This repetition works, but it becomes difficult to maintain as the
  number of resources grows. The count and for_each meta-arguments
  solve this problem in different ways.

========================================================================
PART 1: REFACTORING SUBNETS WITH COUNT
========================================================================

1. ADD COUNT-BASED VARIABLES

  Modify variables.tf to add list variables that count can iterate over:

      variable "subnet_cidr_blocks" {
        description = "CIDR blocks for subnets"
        type        = list(string)
        default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      }

      variable "availability_zones" {
        description = "Availability zones for subnets"
        type        = list(string)
        default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
      }

2. REPLACE INDIVIDUAL SUBNETS WITH COUNT

  In main.tf, remove all three individual subnet resources (subnet_1,
  subnet_2, and subnet_3) and replace them with a single resource block
  using count:

      resource "aws_subnet" "subnet" {
        count             = 3
        vpc_id            = aws_vpc.main.id
        cidr_block        = var.subnet_cidr_blocks[count.index]
        availability_zone = var.availability_zones[count.index]

        tags = {
          Name = "subnet-${count.index + 1}"
        }
      }

  Notice how one resource block now creates all three subnets. The
  count.index value (0, 1, 2) is used to look up the corresponding
  CIDR block and availability zone from the list variables.

3. ADD COUNT-BASED OUTPUTS

  Create outputs.tf with the following:

      output "vpc_id" {
        description = "The ID of the VPC"
        value       = aws_vpc.main.id
      }

      output "subnet_ids" {
        description = "The IDs of the subnets"
        value       = aws_subnet.subnet[*].id
      }

  The [*] syntax (splat expression) returns a list of all IDs from the
  count-based resource.

4. DEPLOY AND INSPECT COUNT-BASED SUBNETS

  Since we changed from individual resources to count-based resources,
  Terraform will need to replace them. Run the following commands:
    $ terraform plan
    $ terraform apply

  After applying, inspect the state to see how count-based resources
  are tracked:
    $ terraform state list

  Notice how the subnets are indexed numerically:
    - aws_subnet.subnet[0]
    - aws_subnet.subnet[1]
    - aws_subnet.subnet[2]

  Each resource is identified only by its position in the list.

========================================================================
PART 2: THE COUNT PROBLEM — REMOVING A RESOURCE
========================================================================

5. REMOVE THE MIDDLE SUBNET USING COUNT

  Simulate removing the second subnet (us-east-1b) by updating the
  variables. Modify variables.tf:

      variable "subnet_cidr_blocks" {
        description = "CIDR blocks for subnets"
        type        = list(string)
        default     = ["10.0.1.0/24", "10.0.3.0/24"]  # <-- Removed middle element
      }

      variable "availability_zones" {
        description = "Availability zones for subnets"
        type        = list(string)
        default     = ["us-east-1a", "us-east-1c"]     # <-- Removed middle element
      }

  Also update the count in main.tf:

      resource "aws_subnet" "subnet" {
        count             = 2                           # <-- Updated from 3 to 2
        vpc_id            = aws_vpc.main.id
        cidr_block        = var.subnet_cidr_blocks[count.index]
        availability_zone = var.availability_zones[count.index]

        tags = {
          Name = "subnet-${count.index + 1}"
        }
      }

  Run a plan and carefully examine the output:
    $ terraform plan

  IMPORTANT: Notice what Terraform proposes. Because count uses numeric
  indexes, removing the middle element shifts everything after it:

    - Index 0 ("10.0.1.0/24") stays the same — no change
    - Index 1 was "10.0.2.0/24" but now maps to "10.0.3.0/24" — REPLACED
    - Index 2 ("10.0.3.0/24") no longer exists — DESTROYED

  Terraform wants to destroy and recreate the third subnet instead of
  simply removing the second one. In production, this could cause
  downtime for any resources attached to that subnet.

  DO NOT APPLY these changes. We will revert them in the next step.

6. REVERT THE COUNT CHANGES

  Restore the original three-element lists in variables.tf:

      variable "subnet_cidr_blocks" {
        description = "CIDR blocks for subnets"
        type        = list(string)
        default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      }

      variable "availability_zones" {
        description = "Availability zones for subnets"
        type        = list(string)
        default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
      }

  Restore the count to 3 in main.tf:

      resource "aws_subnet" "subnet" {
        count             = 3
        vpc_id            = aws_vpc.main.id
        cidr_block        = var.subnet_cidr_blocks[count.index]
        availability_zone = var.availability_zones[count.index]

        tags = {
          Name = "subnet-${count.index + 1}"
        }
      }

  Confirm no changes are pending:
    $ terraform plan

  The plan should show "No changes."

========================================================================
PART 3: REFACTORING SUBNETS WITH FOR_EACH
========================================================================

7. ADD FOR_EACH VARIABLES

  Add map variables to variables.tf for use with for_each:

      variable "subnet_config" {
        description = "Map of subnet configurations"
        type        = map(string)
        default = {
          "public"  = "10.0.10.0/24"
          "private" = "10.0.20.0/24"
          "data"    = "10.0.30.0/24"
        }
      }

      variable "subnet_azs" {
        description = "Map of subnet availability zones"
        type        = map(string)
        default = {
          "public"  = "us-east-1a"
          "private" = "us-east-1b"
          "data"    = "us-east-1c"
        }
      }

  Notice the difference: instead of parallel lists indexed by position,
  for_each uses maps where each entry has a meaningful key.

8. ADD FOR_EACH SUBNETS ALONGSIDE COUNT

  Add the for_each subnet resource to main.tf (keep the count-based
  subnets in place so we can compare them side by side):

      resource "aws_subnet" "subnet_foreach" {
        for_each          = var.subnet_config
        vpc_id            = aws_vpc.main.id
        cidr_block        = each.value
        availability_zone = var.subnet_azs[each.key]

        tags = {
          Name = "subnet-${each.key}"
        }
      }

  Update outputs.tf to include the for_each subnets:

      output "subnet_foreach_ids" {
        description = "The IDs of the for_each-based subnets"
        value       = { for k, v in aws_subnet.subnet_foreach : k => v.id }
      }

9. DEPLOY AND COMPARE

  Apply the configuration:
    $ terraform plan
    $ terraform apply

  Inspect the state:
    $ terraform state list

  Compare how the two approaches are tracked:

    Count-based (numeric index):
      - aws_subnet.subnet[0]
      - aws_subnet.subnet[1]
      - aws_subnet.subnet[2]

    For_each-based (string key):
      - aws_subnet.subnet_foreach["data"]
      - aws_subnet.subnet_foreach["private"]
      - aws_subnet.subnet_foreach["public"]

  The for_each resources have meaningful identifiers that don't depend
  on ordering.

========================================================================
PART 4: THE FOR_EACH ADVANTAGE — REMOVING A RESOURCE
========================================================================

10. REMOVE THE MIDDLE SUBNET USING FOR_EACH

  Modify the subnet_config and subnet_azs variables to remove the
  "private" entry:

      variable "subnet_config" {
        description = "Map of subnet configurations"
        type        = map(string)
        default = {
          "public" = "10.0.10.0/24"
          "data"   = "10.0.30.0/24"
                                     # <-- Removed "private" subnet
        }
      }

      variable "subnet_azs" {
        description = "Map of subnet availability zones"
        type        = map(string)
        default = {
          "public" = "us-east-1a"
          "data"   = "us-east-1c"
                                     # <-- Removed "private" AZ
        }
      }

  Run a plan and compare to what happened with count:
    $ terraform plan

  Notice the difference: Terraform proposes destroying ONLY the
  "private" subnet. The "public" and "data" subnets are completely
  untouched — no replacements, no shifts.

  This is the key advantage of for_each: resources are tracked by their
  map key, not by position. Removing an entry only affects that specific
  resource.

  Apply the changes:
    $ terraform apply

========================================================================
PART 6: CLEAN UP
========================================================================

11. DESTROY ALL RESOURCES

  Remove all created resources:
    $ terraform destroy

UNDERSTANDING COUNT VS FOR_EACH
--------------------------------
  Count:
    - Uses numeric indexes (0, 1, 2, ...)
    - Works well for identical resources where order doesn't matter
    - Removing or reordering elements shifts all subsequent indexes
    - Can cause unintended resource destruction and recreation
    - Best for: creating N identical copies of a resource

  For_Each:
    - Uses string keys from a map or set
    - Each resource has a stable, meaningful identifier
    - Removing an entry only affects that specific resource
    - Supports non-uniform configurations via map of objects
    - Best for: resources that differ in configuration or need
      stable identity

  When to use count:
    - Creating multiple identical resources (e.g., N worker nodes)
    - Simple on/off toggles (count = var.enabled ? 1 : 0)

  When to use for_each:
    - Resources with distinct configurations
    - Resources that may be added or removed independently
    - Any case where stable resource identity matters

  Resource References:
    - Count: aws_subnet.subnet[0], aws_subnet.subnet[*].id

ADDITIONAL EXERCISES
--------------------
  - Create multiple IAM users with for_each
  - Add subnet-route table associations using for_each
  - Create multiple S3 buckets with different configurations
  - Try using toset() to convert a list to a set for for_each