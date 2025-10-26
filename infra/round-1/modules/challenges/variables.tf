variable "vpc_id" {
  description = "The ID of the VPC where the challenges subnet will be created."
  type        = string
}
variable "challenges_subnet_cidr" {
  description = "The IPv4 CIDR block for the challenges subnet"
  type        = string
}
variable "challenges_subnet_ipv6_cidr" {
  description = "The IPv6 CIDR block for the challenges subnet"
  type        = string
}
variable "monitoring_ipv6_cidr" {
  type        = string
  description = "The CIDR block for the monitoring server's IPv6 address"
}

variable "ec2_key_pair_name" {
  description = "The name of the EC2 key pair to use for SSH access to challenge instances."
  type        = string
}
variable "assume_policy_ec2" {
  description = "The IAM policy document that allows EC2 instances to assume roles."
  type        = string
}

variable "dns_zone_id" {
  description = "The ID of the Route 53 hosted zone to create records in."
  type        = string
}
variable "internal_dns_zone_name" {
  description = "The name of the internal DNS zone"
  type        = string
}

variable "letsencrypt_ca_server" {
  description = "The Let's Encrypt CA server to use (e.g., production or staging)."
  type        = string
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "github_openid_connect_provider_arn" {
  description = "The ARN of the GitHub OpenID Connect provider in AWS IAM."
  type        = string
}
