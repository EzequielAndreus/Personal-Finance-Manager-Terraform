# -------------------------------
# EC2 Outputs
# -------------------------------
output "ec2_instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "ec2_instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "ec2_instance_private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = aws_instance.web.private_ip
}

output "ec2_instance_public_dns" {
  description = "The public DNS of the EC2 instance"
  value       = aws_instance.web.public_dns
}

output "ec2_instance_ami" {
  description = "The AMI of the EC2 instance"
  value       = aws_instance.web.ami
}

output "ec2_instance_name_tag" {
  description = "The Name tag of the EC2 instance"
  value       = aws_instance.web.tags["Name"]
}

# -------------------------------
# Networking Outputs
# -------------------------------
output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = data.aws_subnet.existing.id
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = data.aws_vpc.existing.id
}
