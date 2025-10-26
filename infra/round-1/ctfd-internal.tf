resource "aws_subnet" "ctfd-private-primary" {
  vpc_id                  = aws_vpc.ctf.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = aws_subnet.ctfd.availability_zone
  ipv6_cidr_block         = cidrsubnet(aws_vpc.ctf.ipv6_cidr_block, 8, 1)
  map_public_ip_on_launch = false
  tags = {
    Name = "CTFd private subnet - Primary"
  }
}
resource "aws_subnet" "ctfd-private-secondary" {
  vpc_id                  = aws_vpc.ctf.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = endswith(aws_subnet.ctfd.availability_zone, "a") ? "${substr(aws_subnet.ctfd.availability_zone, 0, length(aws_subnet.ctfd.availability_zone) - 1)}b" : "${substr(aws_subnet.ctfd.availability_zone, 0, length(aws_subnet.ctfd.availability_zone) - 1)}a"
  ipv6_cidr_block         = cidrsubnet(aws_vpc.ctf.ipv6_cidr_block, 8, 2)
  map_public_ip_on_launch = false
  tags = {
    Name = "CTFd private subnet - Secondary"
  }
}
resource "aws_route_table_association" "ctfd-private-primary" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.ctfd-private-primary.id
}
resource "aws_route_table_association" "ctfd-private-secondary" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.ctfd-private-secondary.id
}

resource "aws_network_acl" "ctfd-private" {
  vpc_id = aws_vpc.ctf.id

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = aws_subnet.ctfd.cidr_block
    from_port  = 3306
    to_port    = 3306
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = aws_subnet.ctfd.cidr_block
    from_port  = 6379
    to_port    = 6379
  }
  ingress {
    protocol        = "tcp"
    rule_no         = 201
    action          = "allow"
    ipv6_cidr_block = aws_subnet.ctfd.ipv6_cidr_block
    from_port       = 3306
    to_port         = 3306
  }
  ingress {
    protocol        = "tcp"
    rule_no         = 301
    action          = "allow"
    ipv6_cidr_block = aws_subnet.ctfd.ipv6_cidr_block
    from_port       = 6379
    to_port         = 6379
  }
  ingress {
    protocol        = "tcp"
    rule_no         = 401
    action          = "allow"
    ipv6_cidr_block = aws_subnet.monitoring.ipv6_cidr_block
    from_port       = 80
    to_port         = 80
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 500
    action     = "allow"
    cidr_block = aws_subnet.aws-endpoints.cidr_block
    from_port  = 1024
    to_port    = 65535
  }
  ingress {
    protocol        = "tcp"
    rule_no         = 501
    action          = "allow"
    ipv6_cidr_block = aws_subnet.aws-endpoints.ipv6_cidr_block
    from_port       = 1024
    to_port         = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = aws_subnet.ctfd.cidr_block
    from_port  = 1024
    to_port    = 65535
  }
  egress {
    protocol        = "tcp"
    rule_no         = 201
    action          = "allow"
    ipv6_cidr_block = aws_subnet.ctfd.ipv6_cidr_block
    from_port       = 1024
    to_port         = 65535
  }
  egress {
    protocol        = "tcp"
    rule_no         = 301
    action          = "allow"
    ipv6_cidr_block = aws_subnet.monitoring.ipv6_cidr_block
    from_port       = 1024
    to_port         = 65535
  }
  egress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = aws_subnet.aws-endpoints.cidr_block
    from_port  = 1024
    to_port    = 65535
  }
  egress {
    protocol        = "tcp"
    rule_no         = 401
    action          = "allow"
    ipv6_cidr_block = aws_subnet.aws-endpoints.ipv6_cidr_block
    from_port       = 1024
    to_port         = 65535
  }

  subnet_ids = [aws_subnet.ctfd-private-primary.id, aws_subnet.ctfd-private-secondary.id]
  tags = {
    Name = "CTFd private subnet ACL"
  }
}

resource "aws_security_group" "ctfd-db" {
  name        = "ctfd-db"
  description = "Security group for CTFd database"
  vpc_id      = aws_vpc.ctf.id
  ingress {
    description     = "Allow inbound traffic from CTFd SG on MariaDB port"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ctfd.id]
  }
}

resource "aws_db_subnet_group" "ctfd" {
  name       = "ctfd_${terraform.workspace}"
  subnet_ids = [aws_subnet.ctfd-private-primary.id, aws_subnet.ctfd-private-secondary.id]
  tags = {
    Name = "Subnet group for CTFd database"
  }
}
resource "aws_db_instance" "ctfd" {
  db_name = "ctfd_${terraform.workspace}"
  engine  = "mariadb"

  # Free tier configs :)
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  username                    = "ctfd"
  manage_master_user_password = true

  network_type         = "DUAL"
  db_subnet_group_name = aws_db_subnet_group.ctfd.name
  multi_az             = false

  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.ctfd-db.id]

  skip_final_snapshot       = terraform.workspace != "production"
  final_snapshot_identifier = terraform.workspace == "production" ? "ctfd-db-final-snapshot" : null
}

resource "aws_security_group" "ctfd-redis" {
  name        = "ctfd-redis"
  description = "Security group for CTFd Redis cache"
  vpc_id      = aws_vpc.ctf.id
  ingress {
    description     = "Allow inbound traffic from CTFd SG on Redis port"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ctfd.id]
  }
}
resource "aws_elasticache_subnet_group" "ctfd" {
  name       = "ctfd-${terraform.workspace}"
  subnet_ids = [aws_subnet.ctfd-private-primary.id, aws_subnet.ctfd-private-secondary.id]
  tags = {
    Name = "Subnet group for CTFd Redis"
  }
}
resource "aws_elasticache_cluster" "ctfd" {
  cluster_id = "ctfd-redis-${terraform.workspace}"
  engine     = "redis"

  node_type       = "cache.t3.micro"
  num_cache_nodes = 1

  network_type       = "dual_stack"
  subnet_group_name  = aws_elasticache_subnet_group.ctfd.name
  security_group_ids = [aws_security_group.ctfd-redis.id]
}
