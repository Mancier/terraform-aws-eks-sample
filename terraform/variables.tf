variable "aws_region" {
  default = "us-east-1"
}

variable "cluster_name" {
  default = "terraform-eks"
  type    = string
}

variable "worker_type" {
  default     = [ "t2.micro" ]
  description = "instance type for workers"
}

variable "credentials_path" {
  type        = string
  description = "Credentials path"
  default     = "~/.aws/credentials"
}

variable "profile" {
  type        = string
  description = "(optional) describe your variable"
  default     = "default"
}

variable "environment" {
  default = "production"
}

variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type        = list(string)
  description = "CIDR of public subnet ips"
  default     = ["10.0.0.0/22","10.0.16.0/22", "10.0.32.0/22"]
}

variable "private_subnet_cidr" {
  type        = list(string)
  description = "CIDR of public subnet ips"
  default     = ["10.0.48.0/22","10.0.64.0/22", "10.0.80.0/22"]
}

variable "access_key" {}

variable "secret_key" {}
