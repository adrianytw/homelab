# RouterOS SNMP Monitoring

## Purpose

Expose RouterOS resource metrics to the internal Prometheus SNMP exporter using
read-only SNMPv3 `authPriv` restricted to `nmac` at `192.168.88.20`.

## Prerequisites

- Take and review a fresh RouterOS binary backup and full text export.
- Confirm the encrypted `routeros-snmp` Secret decrypts successfully.
- Confirm SSH, WinBox/local-console recovery, DNS, DHCP, and AdGuard are healthy.
- Obtain explicit approval for this RouterOS change.

## Change

Supply the generated SOPS-managed authentication and privacy passwords without
printing or saving them in shell history, then run:

```routeros
/snmp community add name=prometheus addresses=192.168.88.20/32 security=private read-access=yes write-access=no authentication-protocol=SHA1 authentication-password="<auth-password>" encryption-protocol=AES encryption-password="<priv-password>"
/snmp community disable [find where name="public"]
/snmp set enabled=yes
```

Do not enable write access, traps, SNMPv1/v2c, or a wider source range.

## Validation

- The `prometheus` community is `security=private`, read-only, and restricted to
  `192.168.88.20/32`; the default `public` community is disabled.
- Prometheus reports `up{job="router"} == 1` and receives CPU, memory, storage,
  temperature, and uptime metrics.
- Router, AdGuard, client DNS through `192.168.88.1`, DHCP, Wi-Fi, and WireGuard
  remain healthy.

## Rollback

```routeros
/snmp set enabled=no
/snmp community remove [find where name="prometheus"]
/snmp community enable [find where name="public"]
```

Remove the exporter scrape configuration and encrypted Secret only after SNMP
is disabled and the baseline RouterOS services are reconfirmed.
