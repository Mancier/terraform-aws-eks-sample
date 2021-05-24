terraform {
  required_version = ">= 0.15"
  backend "local" {
    path = "terraform/states/terraform.tfstate"
    workspace_dir = "terraform/"
  }
}
