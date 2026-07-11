variable "adguard_host" {
  type = string
}

variable "adguard_username" {
  type = string
}

variable "adguard_password" {
  type      = string
  sensitive = true
}

provider "adguard" {
  host     = var.adguard_host
  username = var.adguard_username
  password = var.adguard_password
  scheme   = "https"
  insecure = false
}
