variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}
variable "subnet_id" {
  description = "The ID of the subnet"
  type        = string
}
variable "subnet_ipv6_cidr_block" {
  description = "The IPv6 CIDR block of the subnet"
  type        = string
}
variable "sg_id" {
  description = "The security group ID for the challenge server"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
variable "instance_profile_name" {
  description = "EC2 instance profile name"
  type        = string
  default     = null
}

variable "server_index" {
  description = "The index of the insider threat server"
  type        = number
}
variable "ami_id" {
  description = "The AMI ID for the challenge server"
  type        = string
}
variable "ec2_key_pair_name" {
  description = "The name of the EC2 key pair"
  type        = string
}

variable "letsencrypt_ca_server" {
  description = "The Let's Encrypt CA server URL"
  type        = string
}
variable "auth_middleware_data" {
  description = "The Traefik auth middleware data"
  type        = string
}

variable "compose_file" {
  description = "Docker Compose file contents"
  type        = string
}
variable "custom_script" {
  description = "Custom script to run on instance initialization"
  type        = string
  default     = ""
}

variable "dns_zone_id" {
  description = "The Route53 hosted zone ID"
  type        = string
}
variable "dns_zone_name" {
  description = "The Route53 hosted zone name"
  type        = string
}
variable "internal_dns_zone_name" {
  description = "The internal DNS zone name"
  type        = string
}

variable "dns_names" {
  description = "List of DNS names for the challenge server"
  type        = list(string)
}
