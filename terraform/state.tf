# Configure the TF state location

terraform {
  backend "s3" {
    bucket = "deployment-state"
    region = "us-east-1"
  }
}
