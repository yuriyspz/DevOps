terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = ">= 4.2.0"
        }
    }
    required_version = ">= 1.2.0"
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_secretsmanager_secret" "my_secret" {
  name = "my-secret"
  
}

resource "aws_secretsmanager_secret_version" "pass_value" {
  secret_id = aws_secretsmanager_secret.my_secret.id
  secret_string = random_password.password.result
  
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
  ami           = var.ubuntu_ami
  instance_type = var.free_tier_instance_type
  key_name = "deployer"
  security_groups = [aws_security_group.allow_ssh.name]
  
  ### Install Docker
  user_data = file("docker.sh")

  tags = {
    Name = "test_server"
  }
}
