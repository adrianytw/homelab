# LAN IP Plan

This is the flat-LAN plan for `192.168.88.0/24`. VLANs stay deferred.

Do not shrink the DHCP pool until current leases are reviewed and the router has a fresh backup/export.

## Current DHCP

| Item | Value |
| --- | --- |
| Active subnet | `192.168.88.0/24` |
| Router | `192.168.88.1` |
| Current DHCP pool | `192.168.88.10-192.168.88.254` |
| Future DHCP pool target | `192.168.88.100-192.168.88.254` |
| Client DNS | `192.168.88.1` |

## Reserved Addresses

| Address | Name | Owner | Status | Notes |
| --- | --- | --- | --- | --- |
| `192.168.88.1` | `router` / `uwuroute` | MikroTik | current | RouterOS gateway, DHCP, DNS entrypoint |
| `192.168.88.20` | `nmac` | MacBook Pro | reserve now | k3s host and ingress endpoint |
| `192.168.88.30` | `ha` | Home Assistant VM | target later | Preferred stable HA slot after planned migration |
| `192.168.88.84` | `homeassistant` | Home Assistant VM | reserve now | Current working lease; keep until migration window |

## Address Blocks

| Range | Use | Rule |
| --- | --- | --- |
| `192.168.88.1` | Router | Fixed |
| `192.168.88.2-192.168.88.9` | Network infrastructure | Reserve; do not use casually |
| `192.168.88.10-192.168.88.19` | Spare infrastructure | Reserve after future DHCP pool shrink |
| `192.168.88.20-192.168.88.29` | Homelab hosts | `nmac` lives here |
| `192.168.88.30-192.168.88.39` | Home automation VMs | HA target slot lives here |
| `192.168.88.40-192.168.88.79` | Future services / appliances | Reserve for known static needs |
| `192.168.88.80-192.168.88.99` | Transitional static leases | Existing devices may stay here short term |
| `192.168.88.100-192.168.88.254` | General DHCP clients | Future dynamic pool target |

## Next Reservations

Create or confirm these RouterOS static DHCP leases:

| Name | Address | MAC |
| --- | --- | --- |
| `nmac` | `192.168.88.20` | `F8:E4:3B:54:E7:03` |
| `homeassistant` | `192.168.88.84` | `52:54:00:D4:BD:37` |

Keep `192.168.88.30` unused until the Home Assistant migration is scheduled.
