resource "aws_vpc" "main" {
        cidr_block = var.vpc_cidr

        tags = {
          Name = "${var.prefix}-vpc"
        }
      }

       import {
        to = aws_subnet.app
        id = "subnet-0dc111224e0197aaf"
      }
resource "aws_subnet" "app" {
        vpc_id     = aws_vpc.main.id
        cidr_block = var.subnet_cidr

        tags = {
          Name = "${var.prefix}-subnet"
        }
      }
        import {
        to = aws_security_group.main
        id = "sg-0dc5a485bffefef25"
      }
         resource "aws_security_group" "main" {
        name        = "${var.prefix}-web-sg"
        description = "Lab security group"
        vpc_id      = aws_vpc.main.id

        tags = {
          Name = "${var.prefix}-web-sg"
        }
      }
