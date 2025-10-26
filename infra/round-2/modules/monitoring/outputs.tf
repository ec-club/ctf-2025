output "cidr_block" {
  value = aws_subnet.monitoring-internal.cidr_block
}
output "ipv6_cidr_block" {
  value = aws_subnet.monitoring-internal.ipv6_cidr_block
}
