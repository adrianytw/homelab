terraform {
  required_version = "~> 1.12.0"

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.99.1"
    }
  }
}

variable "routeros_username" {
  type = string
}

variable "routeros_password" {
  type      = string
  sensitive = true
}

provider "routeros" {
  hosturl        = "https://192.168.88.1:8443"
  username       = var.routeros_username
  password       = var.routeros_password
  ca_certificate = "${path.module}/homelab-router-ca.crt"
  insecure       = false
}
