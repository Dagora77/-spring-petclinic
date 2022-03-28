output "tools_sg_id" {
  value = aws_security_group.tools_sc.id
}

output "webserver_sg_id" {
  value = aws_security_group.my_webserver.id
}
