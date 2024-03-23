
data "aws_caller_identity" "current" {}

output "caller_user" {
  value = data.aws_caller_identity.current.arn
}