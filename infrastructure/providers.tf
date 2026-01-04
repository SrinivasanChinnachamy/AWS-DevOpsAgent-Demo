terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "terraform-statefile-bucket-0503"
    key    = "devops-agent-demo/terraform.tfstate"
    region = "us-east-1"
    
    # S3 native locking
    skip_metadata_api_check     = false
    skip_region_validation      = false
    skip_credentials_validation = false
  }
}

provider "aws" {
  region = var.aws_region
}