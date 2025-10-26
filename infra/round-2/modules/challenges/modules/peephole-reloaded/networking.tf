resource "aws_eip" "peephole-reloaded" {
  domain            = "vpc"
  network_interface = module.challenge-instance.nic_id
}

resource "aws_route53_record" "challenge-server_ipv6" {
  zone_id = var.dns_zone_id
  name    = "peephole-reloaded"
  type    = "A"
  ttl     = 300
  records = [aws_eip.peephole-reloaded.public_ip]
}
