variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}
variable "vpc_ipv4_cidr_blocks" {
  description = "The IPv4 CIDR blocks for the VPCs"
  type        = list(string)
}
variable "vpc_ipv6_cidr_blocks" {
  description = "The IPv6 CIDR blocks for the VPCs"
  type        = list(string)
}
variable "nat_route_table_id" {
  description = "The ID of the NAT routing table"
  type        = string
}
variable "public_route_table_id" {
  description = "The ID of the public routing table"
  type        = string
}

variable "monitoring_subnet_index" {
  description = "Index of the subnet for monitoring resources"
  type        = number
}
variable "monitoring_internal_subnet_index" {
  description = "Index of the internal subnet for monitoring"
  type        = number
}

variable "ec2_key_pair_name" {
  description = "The name of the EC2 key pair"
  type        = string
}
variable "assume_policy_ec2" {
  description = "The assume role policy for EC2"
  type        = string
}
variable "instance_connect_endpoint_sg_ids" {
  description = "List of security group IDs for EC2 Instance Connect Endpoint"
  type        = list(string)
}

variable "s3_cidr_blocks" {
  description = "List of CIDR blocks for S3 VPC endpoint"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "The ID of the Route53 public hosted zone"
  type        = string
}
variable "route53_zone_name" {
  description = "The name of the Route53 public hosted zone"
  type        = string
}
variable "route53_internal_zone_id" {
  description = "The ID of the Route53 internal hosted zone"
  type        = string
}
variable "route53_internal_zone_id_singapore" {
  description = "The ID of the Singapore Route53 internal hosted zone"
  type        = string
}
variable "route53_internal_zone_name" {
  description = "The name of the Route53 internal hosted zone"
  type        = string
}

variable "letsencrypt_ca_server" {
  description = "The Let's Encrypt CA server URL"
  type        = string
}
