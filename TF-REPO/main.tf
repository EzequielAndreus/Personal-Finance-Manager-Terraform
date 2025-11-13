# -------------------------------
# Provider
# -------------------------------
provider "aws" {
  region = var.region
}

# -------------------------------
# Use existing VPC and Subnet
# -------------------------------
data "aws_vpc" "existing" {
  id = "vpc-03c3fc06bad8f48d1"
}

data "aws_subnet" "existing" {
  id = "subnet-014ee6fa367966332"
}

# -------------------------------
# Internet Gateway (reuse existing one)
# -------------------------------
data "aws_internet_gateway" "existing" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.existing.id]
  }
}

# -------------------------------
# Route Table for Public Subnet
# -------------------------------
resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.existing.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.existing.id
  }

  tags = {
    Name    = "${var.project_name}-public-rt"
    Project = var.project_name
  }
}

# -------------------------------
# Associate Route Table with existing Subnet
# -------------------------------
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = data.aws_subnet.existing.id
  route_table_id = aws_route_table.public.id
}

# -------------------------------
# EC2 Instance
# -------------------------------
resource "aws_instance" "web" {
  ami           = var.instance_ami
  instance_type = var.instance_type
  subnet_id     = data.aws_subnet.existing.id
  key_name      = var.key_name

  associate_public_ip_address = true

  tags = {
    Name    = "${var.project_name}-ec2"
    Project = var.project_name
  }
}
