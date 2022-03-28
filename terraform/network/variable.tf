variable "region" {
  default = "us-east-2"
}

variable "env" {
  default = "main"
}

variable "cidr_block" {
  default = "10.0.0.0/16"
}

variable "public_subnet_a_cidr_block" {
  type        = string
  description = "valid subnets to assign to server"
  default     = "10.0.10.0/24"
}

variable "public_subnet_b_cidr_block" {
  type        = string
  description = "valid subnets to assign to server"
  default     = "10.0.11.0/24"
}

variable "private_subnet_a_cidr_block" {
  type        = string
  description = "valid subnets to assign to server"
  default     = "10.0.20.0/24"
}

variable "private_subnet_b_cidr_block" {
  type        = string
  description = "valid subnets to assign to server"
  default     = "10.0.21.0/24"
}

variable "allow_ports" {
  description = "Enter ports to open"
  type        = list(any)
  default     = ["80", "443", "3306"]
}
