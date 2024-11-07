terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.73.0"
    }
  }

  required_version = "~> 1.3"
}

provider "aws" {
  region = var.region
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "tf-state-technical-challenge-interview" {
  bucket = "tf-state-bucket-technical-challenge-interview"

  tags = {
    Name        = "tf-state-bucket-technical-challenge-interview"
    Environment = "prod"
    purpose     = "technical-challenge insterview"
  }

}
