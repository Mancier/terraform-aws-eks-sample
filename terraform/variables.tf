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