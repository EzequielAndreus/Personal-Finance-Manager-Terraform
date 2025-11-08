terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "finance-tracker-terraform-bucket"
    key            = "terraform/state/finance-tracker.tfstate"
    region         = "sa-east-1"
    dynamodb_table = "terraform-state-locks-finance-tracker"
    encrypt        = true
  }
}
