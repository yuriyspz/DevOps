variable "ubuntu_ami" {
  description = "The AMI to use for the server"
  default     = "ami-0c7217cdde317cfec"
  type        = string
  
}

variable "free_tier_instance_type" {
  description = "The instance type to use for the server"
  default     = "t2.micro"
  type        = string
  
}