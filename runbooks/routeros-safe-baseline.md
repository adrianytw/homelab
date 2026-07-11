# RouterOS Safe Baseline Change

## Purpose

Apply the first small RouterOS cleanup after baseline discovery:

- remove the old WAN TCP `2222` dst-nat rule
- restrict RouterOS admin services to LAN + WireGuard source ranges
- reserve `nmac` at `192.168.88.20`
- reserve the current Home Assistant VM lease at `192.168.88.84`

## Prerequisites

- `ssh router` works from the current computer.
- `make backup-routeros` has completed successfully in the same maintenance window.
- `docs/routeros-next-changes.md` has been reviewed.
- You have a local LAN path to the router if the service allowlist is wrong.
- Do not change the DHCP pool in this runbook.

## Procedure

1. Create a fresh backup/export:

   ```sh
   make backup-routeros
   ```

2. Review the applied command pattern:

   ```sh
   sed -n '/^## Applied Command Set/,/^## Validation/p' docs/routeros-next-changes.md
   ```

3. Apply the commands manually over SSH:

   ```sh
   ssh router
   ```

4. Paste the RouterOS commands from `docs/routeros-next-changes.md`.

For the old TCP `2222` dst-nat, first print NAT rules and remove the matching visible rule number. On RouterOS `7.23.1`, broad `find` selectors did not remove this rule reliably.

## Validation

Run:

```sh
ssh router "/ip firewall nat print detail where dst-port=2222; /ip service print detail; /ip dhcp-server lease print detail where mac-address=F8:E4:3B:54:E7:03; /ip dhcp-server lease print detail where mac-address=52:54:00:D4:BD:37"
```

Expected:

- TCP `2222` dst-nat is gone.
- Enabled RouterOS services are limited to `192.168.88.0/24,192.168.36.0/24`.
- `nmac` is static at `192.168.88.20`.
- Home Assistant is static at `192.168.88.84`.

Also confirm from a LAN client:

```sh
ssh router "/ip dns print; /ip dhcp-server network print detail"
```

Expected DNS remains:

- DHCP clients use `192.168.88.1`
- RouterOS forwards to AdGuard at `10.0.0.2`

## Rollback

If RouterOS service access fails, restore SSH access through WinBox or local access:

```routeros
/ip service set [find name=ssh] address=""
```

If the old WAN TCP `2222` forward must be restored:

```routeros
/ip firewall nat add chain=dstnat action=dst-nat in-interface-list=WAN protocol=tcp dst-port=2222 to-addresses=192.168.88.138 to-ports=2222 comment="temporary restore of old TCP 2222 forward"
```

If DHCP reservations are wrong, inspect the latest backup pack and restore the previous lease settings from the text export.
