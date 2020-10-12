## Provider
terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 2.1"
    }
  }
}

## Variables
# Naming
variable "Project_Prefix" {
  type        = string
  default     = "demo"
  description = "The prefix before all project created resources, including Transit Gateways, attachments and routing tables."
}