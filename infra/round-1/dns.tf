resource "aws_route53_zone" "ctf" {
  name = terraform.workspace == "production" ? "ctf.empasoft.tech" : "ctf.${terraform.workspace}.empasoft.tech"
}
resource "aws_route53_zone" "ctf-internal" {
  name = terraform.workspace == "production" ? "ctf.empasoft.tech" : "ctf.${terraform.workspace}.empasoft.tech"
  vpc {
    vpc_id = aws_vpc.ctf.id
  }
}

resource "aws_route53_zone" "internal" {
  name = terraform.workspace == "production" ? "internal" : "${terraform.workspace}.internal"
  vpc {
    vpc_id = aws_vpc.ctf.id
  }
}
