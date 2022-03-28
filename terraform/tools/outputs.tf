output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}


output "jenkins_private_ip" {
  value = aws_instance.jenkins.private_ip
}
