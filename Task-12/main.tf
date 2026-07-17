moved {
  from = module.s3_read_only_policy
  to   = module.policies["s3-read-only"]
}

moved {
  from = module.cloudwatch_write_policy
  to   = module.policies["cloudwatch-write"]
}

# Create IAM policies using the iam_policy module
module "policies" {
  source             = "./modules/iam_policy"
  for_each           = var.policies
  environment        = var.environment
  policy_name        = each.key
  policy_description = each.value.description
  policy_statements  = each.value.statements
}



module "app_role" {
  source            = "./modules/iam_role"
  environment       = var.environment
  role_name         = "app-role"
  role_description  = "Application role"
  trusted_principal = "ec2.amazonaws.com"
  policy_arns = {
    s3_read_only = module.policies["s3-read-only"].policy_arn
  }
}

module "monitoring_role" {
  source            = "./modules/iam_role"
  environment       = var.environment
  role_name         = "monitoring-role"
  role_description  = "Monitoring role"
  trusted_principal = "lambda.amazonaws.com"
  policy_arns = {
    cloudwatch_write = module.policies["cloudwatch-write"].policy_arn
  }
}

