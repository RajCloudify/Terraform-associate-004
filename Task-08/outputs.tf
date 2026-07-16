output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "The IDs of the subnets"
  value       = aws_subnet.subnet[*].id
}

  output "subnet_foreach_ids" {
        description = "The IDs of the for_each-based subnets"
        value       = { for k, v in aws_subnet.subnet_foreach : k => v.id }
      }