terraform {
  backend "s3" {
    bucket         = "amzn-s3-lhdenis"
    key            = "terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "tfstate-lock"
    encrypt        = true
  }
}
