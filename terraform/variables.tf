variable "aws_region" {
  default = "us-east-1"
}

variable "cluster-name" {
  default = "terraform-eks"
  type    = string
}

variable "worker_type" {
  default     = [ "t2.micro" ]
  description = "instance type for workers"
}

variable "credentials_path" {
  type = string
  description = "Credentials path"
  default = "~/.aws/credentials"
}

variable "profile" {
  type = string
  description = "(optional) describe your variable"
  default = "default"
}