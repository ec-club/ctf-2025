output "public_ip" {
  value = aws_eip.challenge-server.public_ip
}
output "public_ipv6" {
  value = local.ipv6_address
}
