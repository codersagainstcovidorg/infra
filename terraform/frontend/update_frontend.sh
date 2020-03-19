#!/bin/bash
set -e
this_dir=$(dirname $PWD)

terraform init \
  -backend-config="${this_dir}/config/backend.tfvars" \
  -input=false \
  -reconfigure \
  "${this_dir}/cloudfront"

terraform plan \
  -var-file="${this_dir}/config/terraform.tfvars" \
  -out="${this_dir}/terraform.tfplan" \
  -input=false \
  "${this_dir}/cloudfront"

echo
echo "*********************************************************"
echo "Are you sure you want to apply the above plan? type (y/n)"
echo "*********************************************************"

# Read input, timeout after 240s
read -r -t 240
if [ "$REPLY" != "y" ]; then
  echo "quitting"
  exit 0
fi

terraform apply \
    -input=false \
    "${this_dir}/terraform.tfplan"
