provider "aws" {
  region = var.aws_region
  # access_key = var.access_key
  # secret_key = var.secret_key
}

data "aws_availability_zones" "available" {
  filter {
    name   = "zone-name"
    values = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  }
}
