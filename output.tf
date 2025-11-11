output "instance_public_ip" {
  value = aws_instance.mysql_instance.public_ip
}

output "vpc_id" {
  value = data.aws_vpc.default.id
}

output "subnet_id" {
  value = data.aws_subnets.default.ids[0]
}

output "security_group_id" {
  value = aws_security_group.mysql_sg.id
}

