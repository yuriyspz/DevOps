terraform {
  backend "s3" {
        bucket = "yuriitfbucket"
        key    = "terraform.tfstate"
        region = "us-east-1"
      
    }
}