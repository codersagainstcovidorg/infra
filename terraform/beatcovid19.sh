#!/bin/bash
set -e
# PWD + module name + environment
config_dir="$PWD/$1/environments/$2"
module_dir="$PWD/$1/"
out_plan="${module_dir}/terraform.tfplan"

terraform init \
  -backend-config="${config_dir}/config/backend.tfvars" \
  -input=false \
  -reconfigure \
  "${module_dir}/module"

terraform plan \
  -var-file="${config_dir}/config/terraform.tfvars" \
  -out="${out_plan}" \
  -input=false \
  "${module_dir}/module"

echo
echo "*********************************************************"
echo "Are you sure you want to apply the above plan? type (y/n)"
echo "*********************************************************"

# Read input, timeout after 240s
read -r -t 300
if [ "$REPLY" != "y" ]; then
  echo "quitting"
  exit 0
fi

terraform apply \
    -input=false \
    "${out_plan}"
