variable "ubuntu_ami" {
  description = "The AMI to use for the server"
  default     = "ami-0c101f26f147fa7fd"
  type        = string
  
}

variable "free_tier_instance_type" {
  description = "The instance type to use for the server"
  default     = "t2.micro"
  type        = string
  
}