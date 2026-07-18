provider "aws" {
  region = "us-east-1"
}
terraform {
  required_version = "~>1.12.0"

  cloud {

    organization = "raj-hcp"

    workspaces {
      name = "hcp-raj"
    }
  }
}
