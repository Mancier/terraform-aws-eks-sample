#! /usr/bin/env bash
echo "Starting terraform apply..."
terraform apply \
    --state=states/terrform.tfstate \
    --state-out=states/terraform.tfstate
