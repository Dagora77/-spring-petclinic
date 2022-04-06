provider "aws" {
  region = var.region
}


//----------------------------------------------------

terraform {
  backend "s3" {
    bucket = "oyamkovyi-3242423-rs"
    key    = "final_project/dtr/terraform.tfstate"
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

data "terraform_remote_state" "security_group" {
  backend = "s3"
  config = {
    bucket = "oyamkovyi-3242423-rs"
    key    = "final_project/security_group/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "efs" {
  backend = "s3"
  config = {
    bucket = "oyamkovyi-3242423-rs"
    key    = "final_project/efs/terraform.tfstate"
    region = "us-east-1"
  }
}

//=========================================================
//Create insctance for Jenkins server and other tools
data "aws_ami" "amazon_linux_2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}


resource "aws_instance" "registry" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  vpc_security_group_ids      = [data.terraform_remote_state.security_group.outputs.dtr_sg_id]
  subnet_id                   = data.terraform_remote_state.network.outputs.public_b_id
  #iam_instance_profile        = "s3-full"
  key_name   = aws_key_pair.dtr.key_name
  private_ip = "10.0.11.150"

  provisioner "file" {
    source      = "daemon.json"
    destination = "/tmp/daemon.json"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo mkdir /var/lib/docker",
      //    "sudo chown ec2-user /mnt/efs_dtr",
      "sudo yum install -y amazon-efs-utils",
      "sudo mount -t efs -o tls ${data.terraform_remote_state.efs.outputs.dtr_id}:/ /var/lib/docker",
      "sed -i 's/local_ip/${self.private_ip}/' /tmp/daemon.json",
      //    "sudo mv /var/lib/docker /mnt/efs_dtr/docker",
      //    "sudo ln -s /mnt/efs_dtr/docker /var/lib/docker",
      "sudo amazon-linux-extras install docker -y",
      "sudo yum install docker -y",
      "sudo service docker start",
      "sudo systemctl enable docker",
      "sudo usermod -a -G docker ec2-user",
      "sudo mv /tmp/daemon.json /etc/docker/daemon.json",
      "sudo docker run -d --name myregistry --restart=always -p 5000:5000 registry:2",
      "df -T"
    ]
  }


  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("id_rsa")
    host        = self.public_ip
  }


  tags = {
    Name = "${var.env}_dtr"
  }
}

resource "aws_key_pair" "dtr" {
  key_name   = "dtr-key"
  public_key = file("id_rsa.pub")
}
