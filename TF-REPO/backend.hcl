bucket         = "finance-tracker-terraform-bucket"
key            = "terraform/state/terraform.tfstate"
region         = "sa-east-1"
encrypt        = true
dynamodb_table = "terraform-state-locks-finance-tracker"
