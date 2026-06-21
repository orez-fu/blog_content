locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    },
    var.additional_tags
  )

  public_subnets = {
    for index, az in var.availability_zones : az => {
      az   = az
      cidr = cidrsubnet(var.vpc_cidr, 8, index + 1)
    }
  }

  application_subnets = {
    for index, az in var.availability_zones : az => {
      az   = az
      cidr = cidrsubnet(var.vpc_cidr, 8, index + 10)
    }
  }

  data_subnets = {
    for index, az in var.availability_zones : az => {
      az   = az
      cidr = cidrsubnet(var.vpc_cidr, 8, index + 20)
    }
  }

  production_subnets = {
    for index, az in var.availability_zones : az => {
      az   = az
      cidr = cidrsubnet(var.vpc_cidr, 8, index + 30)
    }
  }
}
