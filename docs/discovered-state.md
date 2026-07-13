# Discovered State

Collected read-only over `ssh router` and `ssh nmac`; last refreshed `2026-07-13`.

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
| RouterOS API SSL | enabled on `8729`; certificate `none`; unused by OpenTofu |
| RouterOS HTTPS REST | `www-ssl` on `8443`, LAN/WireGuard restricted, certificate `homelab-router-rest` with IP SAN `192.168.88.1` |
| RouterOS certificates | trusted local `homelab-router-ca`; REST, AdGuard, and Router Web server certificates valid until `2028-10-14` |
| AdGuard HTTPS | trusted `adguard.nairdev.com` reverse proxy on `443`, LAN/WireGuard restricted, HTTP `302` to `/login.html` |
| SNMP monitoring | enabled; `prometheus` is read-only authPriv/private from `192.168.88.20/32`; default `public` community disabled |
| `nmac` lease ID | `*1AB0` |
| Home Assistant lease ID | `*1AB7` |

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
| Root filesystem | `271G`, about `214G` free, `21%` used |
| `/srv/data` | present on the root Btrfs filesystem; local-path PVCs are live |
| k3s | `v1.36.2+k3s1`, enabled and live under Flux |
| Ports `80`/`443`/`6443` | Traefik serves LAN ingress on `80`/`443`; Kubernetes API listens on `6443` |
| SELinux | enforcing |
| Active NetworkManager profile | `br0`; `enu1u1c2` is bridge port `br0-port-enu1u1c2` |
| NetworkManager profile UUID | `br0` is `7f7c386a-3d10-404b-9928-2cd7d5bf4e3c`; port is `a1bbba23-c2c2-4985-addd-c624b780bad0` |
| Host interface MAC | `F8:E4:3B:54:E7:03` |
| Addressing method | NetworkManager DHCP on `br0` |
| Default route / DNS | `192.168.88.1` / `192.168.88.1` |
| Non-interactive sudo | generic sudo unavailable; root-owned maintenance wrapper allowlists app status/backup/recovery and reboot |
| Cockpit socket | enabled/active |
| libvirt VM | `haos` running |
| Firewalld | enabled and active; current zone/rules require privilege and remain blocked |

## Home Assistant VM

| Item | Value |
| --- | --- |
| Name | `haos` |
| State | running |
| Autostart | enabled |
| vCPU | 2 |
| RAM | 4 GiB |
| Network | libvirt bridge interface on host `br0` |
| MAC | `52:54:00:d4:bd:37` |
| Current DHCP lease | `192.168.88.84` |
| Next DHCP action | Reserve current `.84`; keep `.30` as later target convention |
| Disk | `/var/lib/libvirt/images/haos.qcow2` |
| USB vendor/product | `10c4:ea70` |
| USB serial | `00C3A38C` |
