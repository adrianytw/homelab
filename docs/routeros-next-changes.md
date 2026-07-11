# RouterOS Next Changes

These are the safe RouterOS baseline changes applied after backup/export.

No live router change should be applied from this document without a fresh backup and an explicit apply confirmation.

Status: applied on `2026-06-27`.

## Decisions

| Topic | Decision |
| --- | --- |
| WAN dst-nat TCP `2222` | Remove |
| RouterOS admin service restriction | Restrict enabled services to LAN + WireGuard |
| `nmac` lease | Reserve `192.168.88.20` |
| Home Assistant lease | Reserve current `192.168.88.84`; keep `192.168.88.30` as target later |
| DHCP pool shrink | Defer |

## Admin Service Restriction

RouterOS services are the management listeners under `/ip service`, such as SSH, WinBox, WebFig, API, and API-SSL.

Restricting them to LAN + WireGuard means setting their allowed source addresses to:

```text
192.168.88.0/24
192.168.36.0/24
```

This does not create public access. It is defense in depth: even if a firewall rule changes later, RouterOS management services should still reject non-LAN and non-WireGuard clients.

Initial approach:

1. Keep currently enabled services.
2. Add the LAN/WireGuard address allowlist.
3. Confirm SSH access still works from LAN.
4. Later disable unused web/reverse-proxy/API services after confirming they are not needed for OpenTofu or emergency access.

## Applied Command Set

Run only after a fresh `make backup-routeros`.

```routeros
/ip firewall nat print detail
# Remove the printed dstnat rule for TCP 2222 to 192.168.88.138:2222 by visible rule number.

/ip service set [find where name=ssh and dynamic=no] address=192.168.88.0/24,192.168.36.0/24
/ip service set [find where name=www and dynamic=no] address=192.168.88.0/24,192.168.36.0/24
/ip service set [find where name=www-ssl and dynamic=no] address=192.168.88.0/24,192.168.36.0/24
/ip service set [find where name=reverse-proxy and dynamic=no] address=192.168.88.0/24,192.168.36.0/24
/ip service set [find where name=winbox and dynamic=no] address=192.168.88.0/24,192.168.36.0/24
/ip service set [find where name=api and dynamic=no] address=192.168.88.0/24,192.168.36.0/24
/ip service set [find where name=api-ssl and dynamic=no] address=192.168.88.0/24,192.168.36.0/24

/ip dhcp-server lease make-static [find mac-address=F8:E4:3B:54:E7:03]
/ip dhcp-server lease set [find mac-address=F8:E4:3B:54:E7:03] address=192.168.88.20 comment="nmac k3s host"

/ip dhcp-server lease make-static [find mac-address=52:54:00:D4:BD:37]
/ip dhcp-server lease set [find mac-address=52:54:00:D4:BD:37] address=192.168.88.84 comment="Home Assistant VM current; target 192.168.88.30 later"
```

## Validation

```routeros
/ip firewall nat print detail
/ip firewall nat export
/ip service print detail
/ip dhcp-server lease print detail where mac-address=F8:E4:3B:54:E7:03
/ip dhcp-server lease print detail where mac-address=52:54:00:D4:BD:37
/ip dns print
/ip dhcp-server network print detail
```

Expected:

- No NAT rule remains for WAN TCP `2222`.
- Enabled RouterOS services show `192.168.88.0/24,192.168.36.0/24` in `address`.
- `nmac` is static at `192.168.88.20`.
- Home Assistant is static at `192.168.88.84`.
- DHCP DNS remains `192.168.88.1`.
- RouterOS DNS upstream remains `10.0.0.2`.

## Rollback

If SSH access from LAN breaks, use WinBox or local router access and clear the service allowlist:

```routeros
/ip service set [find name=ssh] address=""
```

If the WAN TCP `2222` forward must be restored:

```routeros
/ip firewall nat add chain=dstnat action=dst-nat in-interface-list=WAN protocol=tcp dst-port=2222 to-addresses=192.168.88.138 to-ports=2222 comment="temporary restore of old TCP 2222 forward"
```

If a DHCP reservation causes trouble, remove the static flag or set the previous address back from the RouterOS backup/export.
