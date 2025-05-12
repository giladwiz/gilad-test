provider "aws" {
  region = "us-east-1"
}

# Backend configuration
terraform {
  backend "s3" {
    bucket         = "gilad-terraform-backend" # Replace with your bucket name
    key            = "terraform/state/terraform-onetoone.tfstate" # Path to store the state file
    region         = "us-east-1"
    encrypt        = true                          # Encrypt the state file
  }
}

resource "aws_s3_bucket" "buckets" {

  bucket = "gilad-bucket-onetoone"

  # Default ACL is private, no versioning enabled
  acl = "private"
}

