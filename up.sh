#! /usr/bin/env bash
apply() {
    echo "Executing terraform init"
    terraform init terraform/

    echo "Starting terraform apply..."
    terraform apply \
        -state=terraform/states/terraform.tfstate \
        -state-out=terraform/states/terraform.tfstate \
        -backup=terraform/states/terraform.tfstate.backup \
        terraform/
}

apply
