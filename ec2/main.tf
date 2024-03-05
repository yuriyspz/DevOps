resource "aws_instance" "test_server" {
  ami             = var.ubuntu_ami
  instance_type   = var.free_tier_instance_type
  key_name        = "deployer"
  # security_groups = [security_groups.allow_ssh]
  
  ### Install Docker
  user_data       = file("./docker.sh")

  tags = {
    Name = "test_server"
  }
}

output "aws_instance_public_ip" {
  value = aws_instance.test_server.public_ip
  
}