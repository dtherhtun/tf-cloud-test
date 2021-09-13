variable "vpc" {
  type = object({
    is_enable_vpngw      = bool
    is_enable_natgw      = bool
    is_single_natgw      = bool
    is_one_natgw_per_az  = bool
    is_create_db_sub_grp = bool
    is_create_db_sub_rt  = bool
  })
  default = {
    is_enable_vpngw      = false
    is_enable_natgw      = true
    is_single_natgw      = true
    is_one_natgw_per_az  = false
    is_create_db_sub_grp = true
    is_create_db_sub_rt  = true
  }
  description = <<EOF
  Group variables of aws vpc looks like this:
  ```
  vpc = {
    is_enable_vpngw      = false
    is_enable_natgw      = true
    is_single_natgw      = true
    is_one_natgw_per_az  = false
    is_create_db_sub_grp = true
    is_create_db_sub_rt  = true
  }```
  EOF
}

variable "instances" {
  type = map(any)
  default = {
    bastion = {
      distro        = "ubuntu"
      instance_type = "t3.micro"
      ssh_key       = "dther"
      is_mon_true   = true
      sg            = "ssh_sg"
      network       = "public1"
    }
  }
  description = <<EOF
  Group variables of aws instances looks like this:
  instances = {
      bastion = {}
      web1 = {}
      crawler = {}
  }
  EOF
}
