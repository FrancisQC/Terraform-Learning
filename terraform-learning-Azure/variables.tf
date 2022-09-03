# https://upcloud.com/resources/tutorials/terraform-variables
variable "host_os" {
  type = map(any)
  default = {
    "windows" = "windows"
    "linux"   = "linux"
  }
  # default = "linux"
}

variable "admin_password" {
  type = string
  # default = "blabla"
}

variable "users" {
  type    = list(any)
  default = ["root", "user1", "user2"]
}

variable "plans" {
  type = map(any)
  default = {
    "5USD"  = "1xCPU-1GB"
    "10USD" = "1xCPU-2GB"
    "20USD" = "2xCPU-4GB"
  }
}