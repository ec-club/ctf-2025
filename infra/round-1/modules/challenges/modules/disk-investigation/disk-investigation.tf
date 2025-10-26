data "aws_iam_policy_document" "disk-investigation" {
  statement {
    actions = ["s3:PutObject"]
    resources = [
      "${var.challenge-assets-bucket-arn}/forensic/disk-investigation/*",
    ]
  }
}
resource "aws_iam_role" "disk-investigation" {
  name_prefix        = "disk-investigation-${terraform.workspace}"
  assume_role_policy = var.assume_policy_ec2
}
resource "aws_iam_role_policy" "disk-investigation" {
  name_prefix = "disk-investigation-policy"
  role        = aws_iam_role.disk-investigation.id
  policy      = data.aws_iam_policy_document.disk-investigation.json
}
resource "aws_iam_instance_profile" "disk-investigation" {
  name_prefix = "disk-investigation-${terraform.workspace}"
  role        = aws_iam_role.disk-investigation.name
}

data "aws_ssm_parameter" "challenge_tpm" {
  name = "/empasoft-ctf/amis/challenge/amd64/secure-boot"
}
resource "aws_instance" "disk-investigation" {
  ami = data.aws_ssm_parameter.challenge_tpm.value

  instance_type = "t3.micro"
  primary_network_interface {
    network_interface_id = aws_network_interface.disk-investigation.id
  }

  iam_instance_profile = aws_iam_instance_profile.disk-investigation.name
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  key_name  = var.key_pair_name
  user_data = <<-EOF
#!/bin/bash -e
apt-get update && apt-get install -yq tpm2-tools libtss2-rc0 acl

useradd -s /bin/rbash challenge
usermod -aG tss challenge
mkdir -p /home/challenge/.ssh
ssh-keygen -t ed25519 -f /home/challenge/.ssh/id_ed25519 -N "" -q
aws s3api put-object --bucket ${var.challenge-assets-bucket} --key forensic/disk-investigation/id_ed25519 --body /home/challenge/.ssh/id_ed25519
shred -u /home/challenge/.ssh/id_ed25519

cat << EOT > /home/challenge/.profile
readonly SSH_CONNECTION
export PROMPT_COMMAND='RETRN_VAL=\$?; logger -p local1.notice -t bashcmd "\$SSH_CONNECTION [\$\$]: \$(history 1) \$?"'
readonly PROMPT_COMMAND
EOT
chown challenge:challenge /home/challenge/.profile
chmod 644 /home/challenge/.profile
chattr +i /home/challenge/.profile

cat << EOT > /etc/rsyslog.d/commands.conf
local1.* /var/log/challenge-commands.log
EOT
systemctl restart rsyslog

mkdir -p /opt/alloy
cat << EOT > /opt/alloy/config.alloy
${replace(file("${path.module}/files/disk-investigation.config.alloy"), "$", "\\$")}
EOT
cat << EOT > /opt/alloy/docker-compose.yml
${replace(file("${path.module}/files/docker-compose.yml"), "$", "\\$")}
EOT
export INTERNAL_DOMAIN='${var.internal_dns_zone_name}'
sed -i "s/MONITORING_DOMAIN/${var.internal_dns_zone_name}/g" /opt/alloy/config.alloy
export HOSTNAME=disk-investigation.ctf
cd /opt/alloy && docker compose up -d

mv /home/challenge/.ssh/{id_ed25519.pub,authorized_keys}
chmod 600 /home/challenge/.ssh/authorized_keys
chown -R challenge:challenge /home/challenge/.ssh
chattr +i /home/challenge/.ssh
chattr +i /home/challenge/.ssh/authorized_keys

PASSWORD='https://tinyurl.com/4avtswbp'
cd /home/challenge
tpm2_createprimary -C o -c primary.ctx
tpm2_create -G aes -u key.pub -r key.priv -C primary.ctx
tpm2_load -C primary.ctx -u key.pub -r key.priv -c key.ctx
echo $PASSWORD | tee password.txt
tpm2_encryptdecrypt -c key.ctx -o password.txt.enc password.txt
shred -u password.txt
chown challenge:challenge password.txt.enc key.ctx
chattr +i password.txt.enc key.ctx

setfacl -m u:challenge:0 /tmp /var/tmp /var/crash /var/log $(which ps) $(which pstree)

DISK_FILE=/root/disk
dd if=/dev/zero of=$DISK_FILE bs=1M count=128

LOOP_DEVICE=$(losetup -f)
losetup $LOOP_DEVICE $DISK_FILE

DISK_MAPPER_NAME=secret
echo $PASSWORD | cryptsetup -q luksFormat $LOOP_DEVICE
echo $PASSWORD | cryptsetup luksOpen $LOOP_DEVICE $DISK_MAPPER_NAME

mkfs.ext4 /dev/mapper/$DISK_MAPPER_NAME
mkdir /mnt/$DISK_MAPPER_NAME
mount /dev/mapper/$DISK_MAPPER_NAME /mnt/$DISK_MAPPER_NAME
echo 'ECTF{d1sk_f0r3ns1c____:)___0LqgzoqIUHTSDXrpDDLcqR3JTzXtvHz1Mz3PgFRqqc_}' > /mnt/$DISK_MAPPER_NAME/flag
sync && rm /mnt/$DISK_MAPPER_NAME/flag && sync
umount /mnt/$DISK_MAPPER_NAME
cryptsetup luksClose $DISK_MAPPER_NAME
losetup -d $LOOP_DEVICE

aws s3api put-object --bucket ${var.challenge-assets-bucket} --key forensic/disk-investigation/disk.img --body $DISK_FILE
EOF

  lifecycle {
    ignore_changes = [security_groups]
  }
  tags = {
    Name = "Disk Investigation challenge server"
  }
}

resource "aws_route53_record" "disk-investigation" {
  zone_id = var.dns_zone_id
  name    = "disk-investigation"
  type    = "AAAA"
  ttl     = 300
  records = aws_network_interface.disk-investigation.ipv6_addresses
}
