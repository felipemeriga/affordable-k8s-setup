provider "aws" {
  region = "us-east-1" # Change to your preferred region
}

# Generate a key pair
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Save the private key locally
resource "local_file" "private_key" {
  content  = tls_private_key.ec2_key.private_key_pem
  filename = "${path.module}/server.pem"
}

# Create the AWS key pair using the public key
resource "aws_key_pair" "key_pair" {
  key_name   = "server" # Change this to your desired key name
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "aws_security_group" "instance_sg" {
  name        = "instance-sg"
  description = "Allow SSH and HTTP access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere (restrict as needed)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }
}

resource "aws_instance" "ec2_instance" {
  ami           = "ami-0e2c8caa4b6378d8c" # Ubuntu Server 24.04 LTS (HVM) amd64
  instance_type = "t2.medium"
  key_name      = aws_key_pair.key_pair.key_name
  security_groups = [
    aws_security_group.instance_sg.name
  ]

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  tags = {
    Name = "merigafy-server"
  }
}

resource "aws_eip" "ec2_eip" {
  instance = aws_instance.ec2_instance.id
}

output "instance_public_ip" {
  value = aws_eip.ec2_eip.public_ip
}

output "ssh_command" {
  value = "ssh -i ${path.module}/my-key-pair.pem ec2-user@${aws_eip.ec2_eip.public_ip}"
}
