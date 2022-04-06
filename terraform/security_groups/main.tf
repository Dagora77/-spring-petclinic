provider "aws" {
  region = var.region
}


//----------------------------------------------------

terraform {
  backend "s3" {
    bucket = "oyamkovyi-3242423-rs"
    key    = "final_project/security_group/terraform.tfstate"
    region = "us-east-1"
  }
}

//----------------------------------------------------
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "oyamkovyi-3242423-rs"
    key    = "final_project/network/terraform.tfstate"
    region = "us-east-1"
  }
}


resource "aws_security_group" "my_webserver" {
  name        = "${var.env}_app"
  description = "${var.env}_app"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  tags = {
    Name = "${var.env}_app"
  }
  #tags        = merge(var.common_tags, { Name = "${var.common_tags["Project"]} Server IP" })

  dynamic "ingress" {
    for_each = var.allow_ports_webservers
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16", "77.87.158.69/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "tools_sc" {
  name        = "${var.env_tools}_app"
  description = "${var.env_tools}_app"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  tags = {
    Name = "${var.env_tools}_app"
  }

  dynamic "ingress" {
    for_each = var.allow_ports_tools
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["77.87.158.69/32"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "dtr_sc" {
  name        = "${var.env_dtr}_app"
  description = "${var.env_dtr}_app"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  tags = {
    Name = "${var.env_dtr}_app"
  }

  dynamic "ingress" {
    for_each = var.allow_ports_dtr
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["77.87.158.69/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
