#! /usr/bin/env bash
set -xe

ACTION=${1:-up}

do_up() {
    echo "Executing terraform init"
    terraform -chdir=./terraform init

    echo "Starting terraform apply..."
    terraform -chdir=./terraform apply \
        -state=terraform/states/terraform.tfstate \
        -state-out=terraform/states/terraform.tfstate \
        -backup=terraform/states/terraform.tfstate.backup \
        -var-file="./secrets.tfvars" \
        -auto-approve
}

do_down(){
  terraform -chdir=./terraform destroy \
    -state=terraform/states/terraform.tfstate \
    -state-out=terraform/states/terraform.tfstate \
    -backup=terraform/states/terraform.tfstate.backup \
    -var-file="./secrets.tfvars" \
    -auto-approve
}

if [[ "$ACTION" =~ "up" ]] ;  then
  do_up $*
  exit 0
elif [[ "$ACTION" =~ "down" ]];  then
  do_down $*
  exit 0
else
  echo "Invalid action! Plese use apply/destroy"
  exit 1
fi
