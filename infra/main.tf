terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}



provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "titanic-api"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "vpc" {
  source      = "./modules/vpc"
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

module "eks" {
  source             = "./modules/eks"
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  cluster_version    = var.eks_cluster_version
}

module "rds" {
  source             = "./modules/rds"
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_name            = var.db_name
  db_username        = var.db_username
  instance_class     = var.db_instance_class
}

module "iam" {
  source         = "./modules/iam"
  environment    = var.environment
  eks_cluster_id = module.eks.cluster_id
  eks_oidc_url   = module.eks.oidc_provider_url
}

module "secrets" {
  source      = "./modules/secrets"
  environment = var.environment
  db_password = var.db_password
  db_host     = module.rds.db_endpoint
  db_name     = var.db_name
  db_username = var.db_username
}

