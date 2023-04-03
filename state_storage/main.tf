terraform {
  #############################################################
  ## AFTER RUNNING TERRAFORM APPLY (WITH LOCAL BACKEND)
  ## YOU WILL UNCOMMENT THIS CODE
  ## REMEMBER AND CHANGE THE VALUES BELOW< THEY CANT BE SET IN A VARIABLE
  ## THEN RERUN TERRAFORM INIT
  ## TO SWITCH FROM LOCAL BACKEND TO REMOTE AWS BACKEND
  #############################################################

  /*
  backend "s3" {
    bucket         = "mccracken-cloud-tf-vpc"
    key            = "mccracken-cloud-tf-vpc/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "mccracken-cloud-tf-vpc"
    encrypt        = true
  }
*/
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "> 4.16"
    }
  }
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

locals {
  name = "terraform-state-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = local.name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "terraform_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto_conf" {
  bucket = aws_s3_bucket.terraform_state.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = local.name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

output "backend_config" {
  value = <<EOF
  backend "s3" {
    bucket         = "${aws_s3_bucket.terraform_state.bucket}"
    key            = "${path.cwd}/terraform.tfstate"
    region         = "${var.region}"
    dynamodb_table = "${resource.aws_dynamodb_table.terraform_locks.name}"
    encrypt        = true
  }
  EOF
}
