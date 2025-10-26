#!/bin/bash
set -ex
trap 'echo "An error occurred on line $LINENO." >&2' ERR

if [[ -z "$1" || ! "$1" =~ ^(\/[a-z0-9-]+)+$ ]]; then
	echo "Usage: $0 /path/for/ami/ssm/parameter"
	exit 1
fi
if [[ "$1" == *"arm64" ]]; then
    echo "arm64 AMIs are not supported for this operation"
    exit 0
fi

AMI=$(aws ssm get-parameters --names $1 --query 'Parameters[0].Value' --output text)
AMI_NAME=$(aws ec2 describe-images \
    --image-id "${AMI}" \
    | jq -r '.Images[0].Name')
AMI_SNAPSHOT=$(aws ec2 describe-images --image-id "${AMI}" \
    | jq -r '.Images[0].BlockDeviceMappings[0].Ebs.SnapshotId')
ARCHITECTURE=$(aws ec2 describe-images --image-id "${AMI}" \
		| jq -r '.Images[0].Architecture')

SECURE_BOOT_AMI=$(aws ssm get-parameters --names $1/secure-boot --query 'Parameters[0].Value' --output text)
SECURE_BOOT_AMI_NAME=$(aws ec2 describe-images \
    --image-id "${AMI}" \
    | jq -r '.Images[0].Name')
if [[ "$SECURE_BOOT_AMI_NAME" == "$AMI_NAME-secureboot" ]]; then
    echo "Secure Boot AMI already exists: $SECURE_BOOT_AMI"
    exit 0
fi

SECURE_BOOT_BLOB_FILE=$(mktemp)
wget https://github.com/canonical/aws-secureboot-blob/releases/latest/download/blob.bin -O $SECURE_BOOT_BLOB_FILE
AMI_NEW=$(aws ec2 register-image \
    --uefi-data "$(cat $SECURE_BOOT_BLOB_FILE)" \
    --name "${AMI_NAME}-secureboot" \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs= {SnapshotId=""${AMI_SNAPSHOT}"",DeleteOnTermination=true}" \
    --architecture $ARCHITECTURE \
    --root-device-name /dev/sda1 \
    --virtualization-type hvm \
    --ena-support \
    --boot-mode uefi \
    --tpm-support v2.0 \
    | jq -r '.ImageId')

aws ec2 wait image-available --image-ids "${AMI_NEW}"
aws ssm put-parameter --name "$1/secure-boot" --value "$AMI_NEW" --type "String" --overwrite > /dev/null
echo "New AMI with Secure Boot and TPM registered: $AMI_NEW"
