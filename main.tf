terraform {
  required_version = ">= 0.12"
  backend "local" {
    path = "terraform/states/terraform.tfstate"
    workspace_dir = "terraform/"
  }
}
