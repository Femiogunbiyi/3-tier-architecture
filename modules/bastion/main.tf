# Data source for latest Ubuntu 
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Elastic IP for Bastion Host
resource "aws_eip" "bastion" {
  domain   = "vpc"

   tags = merge(
    var.tags,
    {
       Name =  "${var.environment}-${var.project_name}-bastion-eip"
    }
  )
}

# Bastion Host for EC2 Instance
resource "aws_instance" "bastion" {
  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.key_name
  subnet_id = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile = var.instance_type
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data.sh", {
    environment = var.environment
    project     = var.project_name
  })

  root_block_device {
    volume_size = "gp3"
    volume_type = 20
    delete_on_termination = true
    encrypted = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
    http_put_response_hop_limit = 1
  }

 tags = merge(
    var.tags,
    {
       Name =  "${var.environment}-${var.project_name}-bastion"
    }
  )
}

# Associate Elastic IP with Bastion
resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion.id
}