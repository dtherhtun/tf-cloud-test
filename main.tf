locals {
  project_name = "lts"
  owner        = "Platform-team"
  region       = "us-east-1"
  subnet       = chunklist([for x in cidrsubnets("10.0.0.0/8", 16, 16, 16, 16, 16, 16, 16, 16, 16, 16) : x if x != cidrsubnets("10.0.0.0/8", 16)[0]],3)
}

# create vpc from here
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.7.0"

  name = join("-", [local.project_name, "vpc"])
  cidr = cidrsubnets("10.0.0.0/8", 8)[0]

  azs              = [for x in ["a", "b", "c"] : "${local.region}${x}"]
  private_subnets  = local.subnet[0]
  public_subnets   = local.subnet[1]
  database_subnets = local.subnet[2]

  enable_nat_gateway     = var.vpc.is_enable_natgw
  enable_vpn_gateway     = var.vpc.is_enable_vpngw
  single_nat_gateway     = var.vpc.is_single_natgw
  one_nat_gateway_per_az = var.vpc.is_one_natgw_per_az

  create_database_subnet_group       = var.vpc.is_create_db_sub_grp
  create_database_subnet_route_table = var.vpc.is_create_db_sub_rt

  tags = {
    Name  = local.project_name
    Owner = local.owner
  }
}
