#! /usr/bin/env bash
set -xe
ACTION=${1:-up}
shift
do_up() {
    echo "Executing terraform init"
    terraform init terraform/

    echo "Starting terraform apply..."
    terraform apply \
        -state=terraform/states/terraform.tfstate \
        -state-out=terraform/states/terraform.tfstate \
        -backup=terraform/states/terraform.tfstate.backup \
        -var-file="./terraform/secrets.tfvars" \
        -auto-approve \
        $* \
        terraform/
}

do_down(){
  terraform destroy \
    -state=terraform/states/terraform.tfstate \
    -state-out=terraform/states/terraform.tfstate \
    -backup=terraform/states/terraform.tfstate.backup \
    -var-file="./terraform/secrets.tfvars" \
    -auto-approve \
    $* \
    terraform/
}

if [[ "$ACTION" =~ "up|apply" ]] ;  then
  do_up $*
  exit 0
elif [[ "$ACTION" =~ "down|destroy" ]];  then
  do_down $*
  exit 0
else
  echo "Invalid action! Plese use apply/destroy"
  exit 1
fi
