terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = ">= 4.2.0"
        }
    }
    required_version = ">= 1.2.0"
}

resource "random_password" "this_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_secretsmanager_secret" "my_secret" {
  name = "my-test-secret"
  recovery_window_in_days = 0
  
}

resource "aws_secretsmanager_secret_version" "pass_value" {
  secret_id     = aws_secretsmanager_secret.my_secret.id
  secret_string = random_password.this_password.result
  
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer"
  public_key = file("~/.ssh/id_rsa.pub")
}

module "ec2" {
  source = "./ec2"
}

