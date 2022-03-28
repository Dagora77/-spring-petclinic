provider "aws" {
  region = var.region
}


//----------------------------------------------------

terraform {
  backend "s3" {
    bucket = "oyamkovyi-3242423-rs"
    key    = "final_project/tools/terraform.tfstate"
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


resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  vpc_security_group_ids      = [data.terraform_remote_state.security_group.outputs.tools_sg_id]
  subnet_id                   = data.terraform_remote_state.network.outputs.public_a_id
  #iam_instance_profile        = "s3-full"
  key_name   = aws_key_pair.jenkins.key_name
  private_ip = "10.0.10.184"

  provisioner "file" {
    source      = "daemon.json"
    destination = "/tmp/daemon.json"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo yum install docker -y",
      "sudo service docker start",
      "sudo systemctl enable docker",
      "sudo usermod -a -G docker ec2-user",
      "sudo yum install -y amazon-efs-utils",
      "sudo mkdir /mnt/efs_tools",
      "sudo mount -t efs -o tls ${data.terraform_remote_state.efs.outputs.tools_id}:/ /mnt/efs_tools",
      "sudo chown ec2-user /mnt/efs_tools",
      "sudo mkdir /mnt/efs_dtr",
      "sudo chown ec2-user /mnt/efs_dtr",
      "sudo mount -t efs -o tls ${data.terraform_remote_state.efs.outputs.dtr_id}:/ /mnt/efs_dtr",
      "sed -i 's/local_ip/${self.private_ip}/' /tmp/daemon.json",
      "sudo mv /tmp/daemon.json /etc/docker/daemon.json",
      "sudo systemctl restart docker",
      "sudo docker run -d --name myjenkins --rm -u root -p 8080:8080 -v /mnt/efs_tools/jenkins:/var/jenkins_home -v $(which docker):/usr/bin/docker -v /var/run/docker.sock:/var/run/docker.sock -v /home/ec2-user:/home dagora77/myjenkins",
      "sudo docker run -d --name trustedreg --rm -p 5000:5000 -v /mnt/efs_dtr/trusted_registry/trustedreg:/trusted_registry/ registry:2",
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
    Name = "${var.env}_tools"
  }
}

resource "aws_key_pair" "jenkins" {
  key_name   = "jenkins-key"
  public_key = file("id_rsa.pub")
}

//=======================================================
//Create domain name for jenkins

resource "aws_eip" "jenkins" {
  instance = aws_instance.jenkins.id
  vpc      = true
}

data "aws_route53_zone" "jenkins" {
  name         = "oyamkovyi.link"
  private_zone = false
}

resource "aws_route53_record" "jenkins" {
  zone_id = data.aws_route53_zone.jenkins.id
  name    = "jenkins"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.jenkins.public_ip]

  depends_on = [aws_instance.jenkins]
}
