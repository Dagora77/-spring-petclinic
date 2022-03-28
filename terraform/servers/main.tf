provider "aws" {
  region = var.region
}

//----------------------------------------------------

terraform {
  backend "s3" {
    bucket = "oyamkovyi-3242423-rs"
    key    = "final_project/servers/terraform.tfstate"
    region = "us-east-1"
  }
}


module "test_env" {
  source = "./servers/"
  env    = "test"
}
