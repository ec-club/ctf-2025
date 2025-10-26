#!/bin/bash
set -e
trap 'echo "An error occurred on line $LINENO." >&2' ERR

if [[ -z "$1" || ! "$1" =~ ^(\/[a-z0-9-]+)+$ ]]; then
	echo "Usage: $0 /path/for/ssm/parameter-prefix <Standard|Advanced>"
	exit 1
fi


ssm_tier="Standard"
if [[ -n "$2" ]]; then
	if [[ "$2" == "Standard" || "$2" == "Advanced" ]]; then
		ssm_tier="$2"
	else
		echo "Invalid SSM tier: $2. Must be 'Standard' or 'Advanced'."
		exit 1
	fi
fi

total_images=$(jq -r '.builds | length' manifest.json)

for ((i = 0; i < total_images; i++)); do
	name=$(jq -r ".builds[$i].name" manifest.json)
	image_id=$(jq -r ".builds[$i].artifact_id | split(\":\") | .[1]" manifest.json)
	if [[ -n "$image_id" ]]; then
		aws ssm put-parameter --name "$1/$name" --value "$image_id" --type "String" --tier $ssm_tier --overwrite > /dev/null
	else
		echo "No image ID found for build $i."
	fi
done

rm manifest.json
echo "AMI IDs have been successfully stored in SSM parameters."
