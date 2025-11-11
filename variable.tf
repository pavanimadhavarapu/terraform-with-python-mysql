[200~variable "region" {
  default = "ap-south-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "ami" {
  # Amazon Linux 2 AMI (Mumbai)
  default = "ami-0305d3d91b9f22e84"
}

variable "key_name" {
  description = "Existing AWS key pair name"
  type        = string
}

