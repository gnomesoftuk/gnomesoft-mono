provider "aws" {
  region = "us-east-1"
}

provider "tfe" {
  hostname = var.tfc_hostname
}
