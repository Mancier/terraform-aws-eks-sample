#! /usr/bin/env bash
ACTION=${1:-up}
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

if [[ $ACTION =~ /apply|up/ ]]; then
  do_up
elif [[ $ACTION =~ /destroy|down/ ]]; then
  do_down
else
  echo "Invalid action! Plese use apply/destroy"
  exit 1
fi
