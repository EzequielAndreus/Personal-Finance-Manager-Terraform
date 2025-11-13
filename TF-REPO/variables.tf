# -------------------------------
# General configuration
# -------------------------------
variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "sa-east-1"
}

# -------------------------------
# EC2 instance configuration
# -------------------------------
variable "instance_ami" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0a3c9e4b900b27f2a"  
}
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the EC2 key pair to allow SSH access"
  type        = string
  default     = ""
}

# -------------------------------
# Project Tag
# -------------------------------
variable "project_name" {
  description = "Tag used to identify resources belonging to this project"
  type        = string
  default     = "finance-tracker"
}
