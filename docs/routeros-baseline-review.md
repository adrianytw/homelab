# RouterOS Baseline Review

Generated from backup pack: `/home/nairda/homelab-backups/routeros/20260627T235527Z`

## Baseline

| Item | Value |
| --- | --- |
| Backup timestamp | `20260627T235527Z` |
| RouterOS version | `7.23.1 (stable)` |
| Board | `hAP ax^3` |
| Architecture | `arm64` |
| Binary backup | `routeros.backup` |
| Full text export | `routeros.rsc` |

## DHCP And DNS

| Item | Value |
| --- | --- |
| DHCP pool | `192.168.88.10-192.168.88.254` |
| DHCP lease time | `10m` |
| DHCP DNS handed to clients | `192.168.88.1` |
| RouterOS DNS upstream | `10.0.0.2` |
| RouterOS DNS remote requests | `yes` |

## AdGuard Container

| Item | Value |
| --- | --- |
| veth | `0 R veth1-adguard 1A:CC:40:EA:54:E4 1A:CC:40:EA:54:E5 no 10.0.0.2/24` |
| container | `0 R adguardhome:latest /usb1-part1/adguardhome veth1-adguard 362.9MiB 0` |
| USB storage | `1 BMp usb1-part1 usb1-part1 USB FLASH DRIVE @1'048'576-8'022'654'976` |

## WireGuard

| Item | Value |
| --- | --- |
| Listen port | `443` |
| Peer count | `4` |
| Peer labels | `ipad, macbookpro14, xm-11tpro, iphone15` |

## Firewall And NAT

| Item | Value |
| --- | --- |
| Filter rule count | `13` |
| NAT rule count | `2` |
| WAN dst-nat 2222 | `not found` |

## DHCP Lease Candidates

| Host | Address | MAC | Note |
| --- | --- | --- | --- |
| nmac | `192.168.88.20` | `F8:E4:3B:54:E7:03` | target MacBook/k3s host |
| homeassistant | `192.168.88.84` | `52:54:00:D4:BD:37` | target convention is `192.168.88.30` if free |

## Review Flags

- Home Assistant current lease is 192.168.88.84; target convention is 192.168.88.30 if free.

## Remaining Decisions

- WAN dst-nat `2222 -> 192.168.88.138:2222`: `not found`.
- RouterOS admin services: review whether to disable unused WebFig/API/reverse-proxy later.
- DHCP pool shrink: defer until current leases are reviewed.
- Home Assistant lease: currently `192.168.88.84`; target convention remains `192.168.88.30` for a later migration.

## Safety

This review is sanitized. It intentionally omits sensitive key material and does not include binary backup content.
