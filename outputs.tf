data "aws_caller_identity" "current" {}

output "caller_user" {
  value = data.aws_caller_identity.current.arn
}

output "aws_instance_public_ip" {
  value = module.ec2.aws_instance_public_ip
  
}

output "instance_id" {
  value = module.ec2.instance_id
}