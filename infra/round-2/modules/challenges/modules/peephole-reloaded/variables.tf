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

variable "server_index" {
  description = "The index of the insider threat server"
  type        = number
}

variable "vpc_endpoint_cidr_block" {
  description = "CIDR block for VPC endpoint access"
  type        = string
}
variable "vpc_endpoint_sg_ids" {
  description = "List of security group IDs for VPC endpoints"
  type        = list(string)
}
variable "instance_connect_sg_ids" {
  description = "List of security group IDs for EC2 Instance Connect"
  type        = list(string)
}
variable "monitoring_network_cidr" {
  description = "The IPv4 CIDR block for the monitoring network"
  type        = string
}
variable "monitoring_network_cidr_ipv6" {
  description = "The IPv6 CIDR block for the monitoring network"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID for the challenge server"
  type        = string
}
variable "ec2_key_pair_name" {
  description = "The name of the EC2 key pair"
  type        = string
}
variable "assume_policy_ec2" {
  description = "The assume role policy for EC2"
  type        = string
}

variable "letsencrypt_ca_server" {
  description = "The Let's Encrypt CA server URL"
  type        = string
}
variable "basic_auth_enabled" {
  description = "Whether if enable basic auth middleware"
  type        = bool
}
variable "auth_middleware_data" {
  description = "The Traefik auth middleware data"
  type        = string
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
