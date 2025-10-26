variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the challenge server will be deployed"
}
variable "sg_id" {
  type        = string
  description = "The ID of the security group to associate with the challenge server"
}
variable "subnet_id" {
  type        = string
  description = "The ID of the subnet where the challenge server will be deployed"
}
variable "subnet_cidr_block" {
  type        = string
  description = "The CIDR block for the subnet where the challenge server will be deployed"
}
variable "subnet_ipv6_cidr_block" {
  type        = string
  description = "The IPv6 CIDR block for the subnet where the challenge server will be deployed"
}

variable "server_index" {
  type        = number
  description = "The index of the challenge server (used for IP assignment)"
}

variable "ami_id" {
  type        = string
  description = "The AMI ID to use for the challenge server"
}
variable "instance_type" {
  type        = string
  description = "The instance type for the challenge server"
  default     = "t4g.micro"
}
variable "instance_profile" {
  type        = string
  description = "The IAM instance profile to associate with the challenge server"
}
variable "key_pair_name" {
  type        = string
  description = "The name of the EC2 key pair to use for SSH access"
}

variable "letsencrypt_ca_server" {
  type        = string
  description = "The Let's Encrypt CA server URL"
}

variable "hostname" {
  type        = string
  description = "Hostname of the alloy instance"
}
variable "dns_record_names" {
  type        = list(string)
  description = "The DNS record names for the challenge server"
}
variable "internal_dns_zone_name" {
  type        = string
  description = "The internal DNS zone name for the challenge server"
}
variable "dns_zone_id" {
  type        = string
  description = "The ID of the Route 53 public hosted zone for DNS"
}

variable "compose_file" {
  type        = string
  description = "The Docker Compose file content for the challenge server"
}
