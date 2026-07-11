# Discovered State

Collected read-only over `ssh router` and `ssh nmac`.

## RouterOS

| Item | Value |
| --- | --- |
| Identity | `uwuroute` |
| Board | hAP ax3 |
| Version | RouterOS `7.23.1` |
| Architecture | `arm64` |
| LAN address | `192.168.88.1/24` on `bridge` |
| Container gateway | `10.0.0.1/24` on `docker` |
| WireGuard subnet | `192.168.36.1/24` on `wireguard1` |
| DHCP pool | `192.168.88.10-192.168.88.254` |
| DHCP network DNS | `192.168.88.1` |
| RouterOS DNS server | `10.0.0.2` |
| DNS remote requests | enabled |
| RouterOS API | enabled on `8728`; review before OpenTofu use |
| RouterOS API SSL | enabled on `8729`; certificate `none` |

## AdGuard Container

| Item | Value |
| --- | --- |
| Container | `adguardhome:latest` |
| State | running |
| Interface | `veth1-adguard` |
| Container IP | `10.0.0.2/24` |
| Root dir | `/usb1-part1/adguardhome` |
| Pull tmpdir | `/usb1-part1/pull` |
| Router storage | `usb1-part1` |

## Router Exceptions To Review

| Item | Current value |
| --- | --- |
| WAN dst-nat | TCP `2222` to `192.168.88.138:2222` removed on `2026-06-27` |
| Router services | `www`, `www-ssl`, `reverse-proxy`, `winbox`, `api`, `api-ssl` enabled and restricted to LAN + WireGuard source ranges |
| WireGuard listen port | UDP `443` |

Do not change these without a fresh RouterOS backup/export and explicit apply confirmation.

## MacBook

| Item | Value |
| --- | --- |
| Hostname | `nmac` |
| OS | Fedora Linux Asahi Remix 42 |
| Kernel | `6.19.14-400.asahi.fc42.aarch64+16k` |
| Architecture | `aarch64` |
| Main interface | `enu1u1c2` |
| IP | `192.168.88.20/24` |
| Root filesystem | `271G`, about `223G` free at discovery |
| `/srv/data` | absent |
| k3s | absent |
| Cockpit socket | enabled/active |
| libvirt VM | `haos` running |
| Firewalld active zone | `FedoraWorkstation` on `enu1u1c2` |

## Home Assistant VM

| Item | Value |
| --- | --- |
| Name | `haos` |
| State | running |
| Autostart | enabled |
| vCPU | 2 |
| RAM | 4 GiB |
| Network | direct/macvtap bridge to `enu1u1c2` |
| MAC | `52:54:00:d4:bd:37` |
| Current DHCP lease | `192.168.88.84` |
| Next DHCP action | Reserve current `.84`; keep `.30` as later target convention |
| Disk | `/var/lib/libvirt/images/haos.qcow2` |
| USB vendor/product | `10c4:ea70` |
| USB serial | `00C3A38C` |
