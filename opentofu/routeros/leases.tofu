resource "routeros_ip_dhcp_server_lease" "nmac" {
  address     = "192.168.88.20"
  mac_address = "F8:E4:3B:54:E7:03"
  comment     = "nmac k3s host"
}

resource "routeros_ip_dhcp_server_lease" "home_assistant" {
  address     = "192.168.88.84"
  mac_address = "52:54:00:D4:BD:37"
  comment     = "Home Assistant VM current; target 192.168.88.30 later"
}
