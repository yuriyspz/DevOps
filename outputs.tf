output "aws_instance_public_ip" {
  value = aws_instance.test_server.public_ip
}

data "aws_caller_identity" "current" {}

output "caller_user" {
  value = data.aws_caller_identity.current.arn
}