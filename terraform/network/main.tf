provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket = "oyamkovyi-3242423-rs"
    key    = "final_project/network/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "${var.env}-vpc"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_a_cidr_block
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env}_public_a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_b_cidr_block
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env}_public_b"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_a_cidr_block
  availability_zone = "us-east-2a"


  tags = {
    Name = "${var.env}_private_a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_b_cidr_block
  availability_zone = "us-east-2b"

  tags = {
    Name = "${var.env}_private_b"
  }
}

resource "aws_route_table" "app_public_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app.id
  }

  tags = {
    Name = "${var.env}_public"
  }
}

resource "aws_route_table" "app_private_a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}_private"
  }
}

resource "aws_route_table_association" "app_public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.app_public_a.id
}

resource "aws_route_table_association" "app_private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.app_private_a.id
}

resource "aws_route_table_association" "app_public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.app_public_a.id
}

resource "aws_route_table_association" "app_private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.app_private_a.id
}



resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}_app"
  }
}
