provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket = "oyamkovyi-3242423-rs"
    key    = "final_project/eks/terraform.tfstate"
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
//----------------------------------------------------
data "terraform_remote_state" "security_group" {
  backend = "s3"
  config = {
    bucket = "oyamkovyi-3242423-rs"
    key    = "final_project/security_group/terraform.tfstate"
    region = "us-east-1"
  }
}
//---------------------------------------------------
// Create IAM role and attach it
resource "aws_iam_role" "eks" {
  name = "eks-cluster-app"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

//---------------------------------------------------
// Create eks cluster

resource "aws_eks_cluster" "app" {
  name     = "app"
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    subnet_ids = [data.terraform_remote_state.network.outputs.public_a_id, data.terraform_remote_state.network.outputs.public_b_id]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy
  ]
}

output "endpoint" {
  value = aws_eks_cluster.app.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.app.certificate_authority[0].data
}

//---------------------------------------------------
// Create IAM for node group

resource "aws_iam_role" "node_app" {
  name = "node_app"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_app.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_app.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_app.name
}
//---------------------------------------------------
// Create Group node

resource "aws_eks_node_group" "app" {
  cluster_name    = aws_eks_cluster.app.name
  node_group_name = "petclinic"
  node_role_arn   = aws_iam_role.node_app.arn
  subnet_ids      = [data.terraform_remote_state.network.outputs.public_a_id, data.terraform_remote_state.network.outputs.public_b_id]
  instance_types  = [var.instance_type_nodes]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
  ]
}
//---------------------------------------------------
// Create host to contorl EKS

data "aws_ami" "amazon_linux_2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  vpc_security_group_ids      = [data.terraform_remote_state.security_group.outputs.tools_sg_id]
  subnet_id                   = data.terraform_remote_state.network.outputs.public_a_id
  #iam_instance_profile        = "s3-full"
  key_name   = aws_key_pair.bastion.key_name
  private_ip = "10.0.10.190"
  #  iam_instance_profile = "node_app"
  user_data = file("user_data.sh")



  tags = {
    Name = "${var.env}_bastion"
  }


  depends_on = [
    aws_eks_cluster.app
  ]
}

resource "aws_key_pair" "bastion" {
  key_name   = "bastion-key"
  public_key = file("id_rsa.pub")
}
