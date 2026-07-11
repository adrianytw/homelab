# Recovery command log

No Home Assistant shutdown, backup, restore, or network migration command has run. Read-only VM facts were collected over SSH on `2026-07-11`.

The HA and `/srv/data` procedures were expanded from placeholders, but remain review-gated and unexecuted.

## 2026-07-11 bridge and firewall evidence

```sh
ssh -o BatchMode=yes -o ConnectTimeout=8 nmac 'timeout 6 nmcli -f connection.id,connection.uuid,connection.type,connection.interface-name,802-3-ethernet.cloned-mac-address,ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns,ipv4.never-default,ipv6.method connection show "Wired connection 2"; timeout 6 nmcli -f GENERAL.CONNECTION,GENERAL.DEVICE,GENERAL.TYPE,GENERAL.HWADDR,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show enu1u1c2; ip -brief link; ip route show'
ssh -o BatchMode=yes -o ConnectTimeout=8 nmac 'timeout 6 firewall-cmd --state 2>&1 || true; systemctl is-active firewalld; systemctl is-enabled firewalld; timeout 6 virsh domiflist haos --inactive'
```

Outcome: the active DHCP profile UUID, host MAC, route, DNS, and macvtap presence were confirmed. Firewalld is enabled/active, but rule inventory and inactive libvirt XML are privilege-gated. The HA bridge and k3s/firewall execution packets were prepared; no live change ran.
