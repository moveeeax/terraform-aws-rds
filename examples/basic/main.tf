terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

variable "region" {
  description = "AWS region to deploy the example database into."
  type        = string
  default     = "us-east-1"
}

variable "db_password" {
  description = "Master password for the example database."
  type        = string
  sensitive   = true
}

provider "aws" {
  region = var.region
}

module "rds" {
  source = "../.."

  identifier        = "example-postgres"
  engine            = "postgres"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "appdb"
  username = "appadmin"
  password = var.db_password

  # This example is a throwaway sandbox, so it opts out of the module's
  # production defaults to keep `terraform destroy` a one-step operation.
  # Leave all three at their defaults for anything you care about.
  deletion_protection     = false
  skip_final_snapshot     = true
  backup_retention_period = 0

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "db_endpoint" {
  value = module.rds.endpoint
}
