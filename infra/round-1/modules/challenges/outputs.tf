output "challenges_subnet_cidr" {
  value = aws_subnet.challenges.cidr_block
}
output "challenges_subnet_ipv6_cidr" {
  value = aws_subnet.challenges.ipv6_cidr_block
}
