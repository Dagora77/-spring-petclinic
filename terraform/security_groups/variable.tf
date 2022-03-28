variable "region" {
  default = "us-east-2"
}

variable "env" {
  default = "main"
}

variable "env_tools" {
  default = "main_tools"
}

variable "allow_ports_webservers" {
  description = "Enter ports to open"
  type        = list(any)
  default     = ["80", "8080"]
}

variable "allow_ports_tools" {
  description = "Enter ports to open"
  type        = list(any)
  default     = ["80", "8080", "2049", "1234"]
}
