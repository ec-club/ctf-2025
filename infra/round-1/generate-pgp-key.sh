#!/usr/bin/env bash

KEY_NAME=ctfd-pgp-key
REGION=ap-east-1

if [ "$1" == "--help" ]; then
	echo "Usage: $0 [--force]"
	echo "  --force    Overwrite existing secret value"
	exit 0
fi

if aws secretsmanager describe-secret --secret-id $KEY_NAME --region $REGION >/dev/null 2>&1; then
	if aws secretsmanager get-secret-value --secret-id $KEY_NAME --region $REGION >/dev/null 2>&1; then
		if [ "$1" != "--force" ]; then
			echo "Secret with value exists. Exiting."
			exit 0
		fi
	fi
else
	aws secretsmanager create-secret --name $KEY_NAME --region $REGION >/dev/null
fi

EMAIL=ctfd@ctf.empasoft.tech

cat > batch_file <<EOF
%echo Generating a GPG key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Expire-Date: 0
Name-Real: CTFd
Name-Email: $EMAIL
Name-Comment: Empasoft CTFd key
%no-protection
%commit
%echo Done!
EOF

gpg --batch --generate-key batch_file

rm batch_file

# See: https://github.com/hashicorp/terraform/issues/10835#issuecomment-277255987
mkdir -p keys && gpg --export $EMAIL | base64 > keys/ctfd_public.key
gpg --armor --export-secret-keys $EMAIL > ctfd_private.key
gpg --delete-secret-keys $EMAIL || true
gpg --delete-key $EMAIL || true

aws secretsmanager put-secret-value --secret-id $KEY_NAME --secret-string file://ctfd_private.key --region $REGION >/dev/null && rm ctfd_private.key
