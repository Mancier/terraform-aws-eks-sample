#! /usr/bin/env bash
echo "Starting terraform apply..."
terraform destroy \
    -state-out=terraform/states/terraform.tfstate \
    -var-file="./terraform/secrets.tfvars" \
    terraform/
