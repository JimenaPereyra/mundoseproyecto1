terraform {
  backend "s3" {
    bucket         = "proyectofinal-terraform-state"   # Cambiar por tu bucket
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "proyectofinal-locks"            # Tabla para locking
    encrypt        = true
  }

  required_providers {
    aws = { source = "hashicorp/aws" }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}
