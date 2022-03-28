provider "aws" {
  region = var.region
}


//----------------------------------------------------

terraform {
  backend "s3" {
    bucket = "oyamkovyi-3242423-rs"
    key    = "final_project/efs/terraform.tfstate"
    region = "us-east-1"
  }
}

//--------------------------------------------------------

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "oyamkovyi-3242423-rs"
    key    = "final_project/network/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "security_group" {
  backend = "s3"
  config = {
    bucket = "oyamkovyi-3242423-rs"
    key    = "final_project/security_group/terraform.tfstate"
    region = "us-east-1"
  }
}
//--------------------------------------------------------
//Storage for Tools
resource "aws_efs_file_system" "tools" {
  creation_token = "my-tools"

  tags = {
    Name = "MyTools"
  }
}

resource "aws_efs_mount_target" "tools_1" {
  file_system_id  = aws_efs_file_system.tools.id
  subnet_id       = data.terraform_remote_state.network.outputs.public_a_id
  security_groups = [data.terraform_remote_state.security_group.outputs.tools_sg_id]
}

resource "aws_efs_mount_target" "tools_2" {
  file_system_id  = aws_efs_file_system.tools.id
  subnet_id       = data.terraform_remote_state.network.outputs.public_b_id
  security_groups = [data.terraform_remote_state.security_group.outputs.tools_sg_id]
}
//--------------------------------------------------------
//Storage for Docker Trusted Registry

resource "aws_efs_file_system" "DTR" {
  creation_token = "DTR"

  tags = {
    Name = "DTR"
  }
}

resource "aws_efs_mount_target" "DTR_1" {
  file_system_id  = aws_efs_file_system.DTR.id
  subnet_id       = data.terraform_remote_state.network.outputs.public_a_id
  security_groups = [data.terraform_remote_state.security_group.outputs.tools_sg_id]
}

resource "aws_efs_mount_target" "DTR_2" {
  file_system_id  = aws_efs_file_system.DTR.id
  subnet_id       = data.terraform_remote_state.network.outputs.public_b_id
  security_groups = [data.terraform_remote_state.security_group.outputs.tools_sg_id]
}
