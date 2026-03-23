terraform {
  required_version = ">=1.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }

  backend "s3" {}
}

provider "aws" {}
