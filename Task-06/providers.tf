terraform {
        required_version = ">= 1.12.2"
        required_providers {
          aws = {
            source  = "hashicorp/aws"
            version = "~> 6.0"
          }
        }
        #  backend "s3" {
        #   bucket       = "lab-tf-state-563227989082"
        #   key          = "networking/terraform.tfstate"
        #   region       = "us-east-1"
        #   use_lockfile = true
        #   encrypt      = true
        # }
      }
      provider "aws" {
        region = var.aws_region
        
      } 


