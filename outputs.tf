output "bastion_public_ip" {
  value       = module.ec2_instance["bastion"].public_ip
  description = "Public Ip of Bastion host"
}
