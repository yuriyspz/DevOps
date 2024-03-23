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
  name                    = "my-test-secret"
  recovery_window_in_days = 0

}

data "aws_secretsmanager_secret" "my_secret_arn" {
  name = aws_secretsmanager_secret.my_secret.name
}

resource "aws_secretsmanager_secret_version" "pass_value" {
  secret_id     = aws_secretsmanager_secret.my_secret.id
  secret_string = random_password.this_password.result
}

output "secret_value" {
  value     = aws_secretsmanager_secret_version.pass_value.secret_string
  sensitive = true
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer"
  public_key = file("~/.ssh/id_rsa.pub")
}

module "security_groups" {
  source = "./sg"

}
resource "aws_instance" "test_server" {
  ami                  = var.ubuntu_ami
  instance_type        = var.free_tier_instance_type
  key_name             = "deployer"
  security_groups      = [module.security_groups.sg_name]
  iam_instance_profile = aws_iam_instance_profile.test_instance_profile.name

  ### pass secret to env
  user_data = <<EOF
  #!/bin/bash
  sudo yum update -y
  sudo yum install -y aws-cli
  val=$(aws secretsmanager get-secret-value --secret-id my-test-secret --query SecretString --output text)
  echo "MY_ENV_SECRET=$val" > .env
  EOF

  tags = {
    Name = "test_server"
  }
}

output "aws_instance_public_ip" {
  value = aws_instance.test_server.public_ip

}

resource "aws_iam_instance_profile" "test_instance_profile" {
  name = "test_profile"
  role = aws_iam_role.test_role.name

}

resource "aws_iam_role_policy" "read_secrets" {
  name = "test_secretmanager_policy"
  role = aws_iam_role.test_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Action": "secretsmanager:GetSecretValue",
        "Resource": "${data.aws_secretsmanager_secret.my_secret_arn.arn}"
    }]
}
EOF
}

resource "aws_iam_role" "test_role" {
  name               = "test_role"
  description        = "A role to allow EC2 instances to read secrets from Secrets Manager"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}
