#! /usr/bin/env bash
echo "Starting terraform apply..."
terraform destroy \
    --state=states/terrform.tfstate \
    --state-out=states/terraform.tfstate
