terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.83.1"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = "1.20.0"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

provider "restapi" {
  uri                  = "https://sheets.googleapis.com"
  write_returns_object = true
  debug                = true

  headers = {
    "Content-Type" = "application/json"
  }

  create_method  = "PUT"
  update_method  = "PUT"
  destroy_method = "PUT"
}