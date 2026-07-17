resource "aws_iam_role" "role" {
  name        = "${var.environment}-${var.role_name}"
  description = var.role_description

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = var.trusted_principal
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "policy_attachments" {
  for_each   = var.policy_arns
  role       = aws_iam_role.role.name
  policy_arn = each.value
}