# CTF infrastructure

## Tools used

Terraform for managing Cloud workloads and Ansible for configuration management. Packer is used to create VM images.

## Cloud infrastructure

### DNS records

DNS records are managed via Route53 with DNSSEC enabled. Refer to [dns.tf](./dns.tf) for details.

### Networking

A dedicated VPC is created for the CTF infrastructure with public and private subnets.

#### Subnet list

| Name                             | CIDR Block    | Internet Access                   | Description                                                                                                              |
| -------------------------------- | ------------- | --------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| CTFd subnet                      | 10.0.1.0/24   | Yes (via IGW)                     | Public subnet for CTFd                                                                                                   |
| CTFd internal subnet - Primary   | 10.0.2.0/24   | No                                | Private subnet for internal services for CTFd: Redis and MariaDB. Also serves as an analytics gateway for CTFd instance. |
| CTFd internal subnet - Secondary | 10.0.3.0/24   | No                                | Private subnet for internal services for CTFd: Redis and MariaDB                                                         |
| Challenges subnet                | 10.0.10.0/24  | Yes (via IGW)                     | Public subnet for challenge instances                                                                                    |
| Monitoring internal subnet       | 10.0.252.0/24 | Partial (S3 via Gateway endpoint) | Private subnet for monitoring services: Prometheus, Loki                                                                 |
| Monitoring subnet                | 10.0.253.0/24 | Yes (via IGW)                     | Subnet for Grafana                                                                                                       |
| Public subnet                    | 10.0.254.0/24 | Yes (via IGW)                     | Public subnet for NAT Gateway and Bastion hosts                                                                          |
| AWS Endpoints subnet             | 10.0.255.0/24 | Yes (via IGW)                     | Private subnet for AWS service endpoints                                                                                 |

## Key services

### CTFd + Traefik

It's deployed in the CTFd subnet. Traefik is used as a reverse proxy and handles TLS termination with Let's Encrypt.

TLS certificates are automatically managed by Traefik and saved in a separate EBS volume to persist them across instance recreations. Let's Encrypt staging environment is used to avoid hitting rate limits during testing.

There are two services related to CTFd deployed to the internal subnet with strict ACLs and SGs: Redis and MariaDB. Elasticache is used for Redis and RDS for MariaDB.

CTFd uploads are stored in a separate S3 bucket with public access. CTFd has an access key and a secret key to access the bucket, which is passed via startup script and GPG private key stored in AWS Secrets Manager.

The CTFd instance is created from a custom AMI built with Packer. The Packer template is located in the `ami/ctfd` directory. The AMI ID is stored in the SSM Parameter Store and is referenced in the Terraform configuration.
