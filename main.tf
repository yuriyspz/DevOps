terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = ">= 4.2.0"
        }
    }
    required_version = ">= 1.2.0"
}

module "ec2" {
  source = "./ec2"
}

data "aws_vpc" "default" {
    default = true
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
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = data.aws_vpc.default.id
  
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
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

resource "aws_lb_target_group" "alb_tg" {
  name = "alb-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id
  target_type = "instance"
  deregistration_delay = 30
  stickiness {
    type = "lb_cookie"
    enabled = true
  }
  health_check {
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "ec2_server" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = module.ec2.instance_id
  port             = 80
  
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.test_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

data "aws_subnets" "example" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "example" {
  for_each = toset(data.aws_subnets.example.ids)
  id       = each.value
}
  
resource "aws_lb" "test_lb" {
  name               = "test-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in data.aws_subnet.example : subnet.id]
  
}