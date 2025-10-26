packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

source "amazon-ebs" "amd64" {
  ami_name      = "ubuntu-24.04-amd64-challenge-{{timestamp}}"
  instance_type = "t3.micro"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }

  ssh_username = "ubuntu"
}

build {
  name    = "ubuntu-24.04-challenge"
  sources = ["source.amazon-ebs.amd64"]

  provisioner "ansible" {
    playbook_file = "playbook.yml"
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
  post-processor "shell-local" {
    inline = ["../ami-id-to-ssm.sh /empasoft-ctf/amis/challenge"]
  }
  post-processor "shell-local" {
    inline = ["../enable-tpm.sh /empasoft-ctf/amis/challenge/amd64"]
  }
}
