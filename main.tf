terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = ">= 4.2.0"
        }
    }
    required_version = ">= 1.2.0"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
  
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "test_server" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
  key_name = "deployer"
  security_groups = [aws_security_group.allow_ssh.name]
  
  ### Install Docker
  user_data = file("docker.sh")

  tags = {
    Name = "test_server"
  }
}

output "aws_instance_public_ip" {
  value = aws_instance.test_server.public_ip
  
}