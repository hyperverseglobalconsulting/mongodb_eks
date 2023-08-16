terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket = "mongodb-on-eks"
    key    = "terraform/terraform.tfstate"
    region = "us-east-2"
    profile = "eksuser"
  }
}

provider "aws" {
  region  = "us-east-2"
  profile = "eksuser"
}

data "aws_caller_identity" "current" {}
