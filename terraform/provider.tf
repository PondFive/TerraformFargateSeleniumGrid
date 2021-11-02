terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      version = "~> 3.63"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
