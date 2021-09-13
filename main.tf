locals {
  project_name = "lts"
  owner        = "Platform-team"
  region       = "us-east-1"
  env          = "development"
  subnet       = chunklist([for x in cidrsubnets("10.0.0.0/8", 16, 16, 16, 16, 16, 16, 16, 16, 16, 16) : x if x != cidrsubnets("10.0.0.0/8", 16)[0]], 3)

  distro = {
    ubuntu = data.aws_ami.ubuntu.id
  }
  network = {
    public1  = module.vpc.public_subnets[0]
    public2  = module.vpc.public_subnets[1]
    public3  = module.vpc.public_subnets[2]
    private1 = module.vpc.private_subnets[0]
    private2 = module.vpc.private_subnets[1]
    private3 = module.vpc.private_subnets[2]
  }
  ssh_key = {
    dther = aws_key_pair.dther_key.key_name
  }
  sg = {
    ssh_sg = module.ssh_sg.security_group_id
  }
}

# create a vpc with public, private, and database subnets upon multi az. create db subnet group and db subnet route table.
# vpc network - 10.0.0.0/16
# public subnet - 10.0.1-3.0/24
# private subnet - 10.0.4-5.0/24
# db subnet - 10.0.7-9.0/24
# can't afford costs for NAT gateway in every az
# create only one NAT gateway
# disable vpn gateway
# create vpc from here
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.7.0"

  name = join("-", [local.project_name, "vpc"])
  cidr = cidrsubnets("10.0.0.0/8", 8)[0]

  azs              = [for x in ["a", "b", "c"] : "${local.region}${x}"]
  public_subnets   = local.subnet[0]
  private_subnets  = local.subnet[1]
  database_subnets = local.subnet[2]

  enable_nat_gateway     = var.vpc.is_enable_natgw
  enable_vpn_gateway     = var.vpc.is_enable_vpngw
  single_nat_gateway     = var.vpc.is_single_natgw
  one_nat_gateway_per_az = var.vpc.is_one_natgw_per_az

  create_database_subnet_group       = var.vpc.is_create_db_sub_grp
  create_database_subnet_route_table = var.vpc.is_create_db_sub_rt

  tags = {
    Environment = local.env
    Owner       = local.owner
  }
}

resource "aws_key_pair" "dther_key" {
  key_name   = "dther"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+20j6uMbFVIU2YkHYCGHjAIAi6Bi4y5ZnfkI7VFYtvAwsknrpdulcD7f90YztXpLs2aVHq0t8y56tLv42UqNCjJrZM8q2B6iLDowM9HMSW680d+kGTLPidRChmr2QHV+UixPBwOyeJubkcP5kCxGXIKjM5zes0CjbEKeF7zRxuBhTVjVq2vrzOzde6N6TE9Ferko/if68zFcBiLIQTEyHOjB2CUFFb2cnoohMZRxIn7CvHmF0EDlxFBpILpj6CaeYBZbgwsKMnuMESqAXXcNucqoC97HoY0HAfLJ5w538CQa+y0FOiFif6AvI0GsZtJUIWMBteRDVUGUSW3m+2q/H"
}

module "ssh_sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/ssh"
  version = "~> 4.0"

  name                = join("-", [local.project_name, "bastion"])
  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  for_each = var.instances
  name     = each.key

  ami                    = coalesce(local.distro[each.value.distro], each.value.distro)
  instance_type          = each.value.instance_type
  key_name               = coalesce(local.ssh_key[each.value.ssh_key], each.value.ssh_key)
  monitoring             = each.value.is_mon_true
  vpc_security_group_ids = [coalesce(local.sg[each.value.sg], each.value.sg)]
  subnet_id              = coalesce(local.network[each.value.network], each.value.network)

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
