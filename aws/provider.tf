terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.65.0"
    }
  }
  backend "s3" {
    bucket         = "amarri-tf-state"
    key            = "fhir.tfstate"
    region         = "us-west-1"
  }
}

provider "aws" {
  region = "us-west-1"
}