#!/bin/bash
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

