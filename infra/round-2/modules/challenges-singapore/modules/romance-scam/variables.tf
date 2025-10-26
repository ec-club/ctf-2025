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

variable "deepseek_token_secret_arn" {
  description = "The ARN of the DeepSeek API token secret in AWS Secrets Manager"
  type        = string
}
variable "deepseek_token_secret_id" {
  description = "The ID of the DeepSeek API token secret in AWS Secrets Manager"
  type        = string
}
variable "ai_endpoint_url" {
  description = "The AI API endpoint URL"
  type        = string
  default     = null
}
variable "ai_model_name" {
  description = "The AI model name"
  type        = string
  default     = null
}
