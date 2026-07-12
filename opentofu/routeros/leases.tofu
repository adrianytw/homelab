resource "routeros_ip_dhcp_server_lease" "nmac" {
  address      = "192.168.88.20"
  block_access = false
  client_id    = "1:f8:e4:3b:54:e7:3"
  mac_address  = "F8:E4:3B:54:E7:03"
  server       = "defconf"
  comment      = "nmac k3s host"
}

resource "routeros_ip_dhcp_server_lease" "home_assistant" {
  address      = "192.168.88.84"
  block_access = false
  client_id    = "1:52:54:0:d4:bd:37"
  mac_address  = "52:54:00:D4:BD:37"
  server       = "defconf"
  comment      = "Home Assistant VM current; target 192.168.88.30 later"
}
