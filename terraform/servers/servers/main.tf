
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
//----------------------------------------------------
data "terraform_remote_state" "efs" {
  backend = "s3"
  config = {
    bucket = "oyamkovyi-3242423-rs"
    key    = "final_project/efs/terraform.tfstate"
    region = "us-east-1"
  }
}
//----------------------------------------------------
data "terraform_remote_state" "tools" {
  backend = "s3"
  config = {
    bucket = "oyamkovyi-3242423-rs"
    key    = "final_project/tools/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_ami" "amazon_linux_2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

resource "aws_instance" "server1" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  vpc_security_group_ids      = [data.terraform_remote_state.security_group.outputs.webserver_sg_id]
  subnet_id                   = data.terraform_remote_state.network.outputs.public_a_id
  #iam_instance_profile        = "s3-full"
  private_ip = "10.0.10.57"
  key_name   = aws_key_pair.servers.key_name

  provisioner "file" {
    source      = "${path.module}/daemon.json"
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
      "sudo mkdir /mnt/efs_dtr",
      "sudo chown ec2-user /mnt/efs_dtr",
      "sed -i 's/local_ip/${data.terraform_remote_state.tools.outputs.jenkins_private_ip}/' /tmp/daemon.json",
      "sudo mv /tmp/daemon.json /etc/docker/daemon.json",
      "sudo systemctl restart docker",
      "sudo mount -t efs -o tls ${data.terraform_remote_state.efs.outputs.dtr_id}:/ /mnt/efs_dtr",
      "sudo docker run -d --name trustedreg --rm -p 5000:5000 -v /mnt/efs_dtr/trusted_registry/trustedreg:/trusted_registry/ registry:2",
      "df -T"
    ]
  }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${path.module}/id_rsa")
    host        = self.public_ip
  }

  tags = {
    Name = "${var.env}_servers"
  }
}

resource "aws_key_pair" "servers" {
  key_name   = "servers-key"
  public_key = file("${path.module}/id_rsa.pub")
}

output "aws_instance_id" {
  value = aws_instance.server1.id
}
