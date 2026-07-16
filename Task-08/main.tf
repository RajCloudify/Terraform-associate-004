resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
      Name = "main-vpc"
    }
  
}

resource "aws_subnet" "subnet" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr_blocks[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "subnet-${count.index + 1}"
  }
}

  resource "aws_subnet" "subnet_foreach" {
        for_each          = var.subnet_config
        vpc_id            = aws_vpc.main.id
        cidr_block        = each.value
        availability_zone = var.subnet_azs[each.key]

        tags = {
          Name = "subnet-${each.key}"
        }
      }


