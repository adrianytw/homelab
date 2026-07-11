# RouterOS imports

Record the RouterOS ID and successful zero-diff plan for each resource. Never batch these imports.

```routeros
/ip dhcp-server lease print show-ids detail where mac-address=F8:E4:3B:54:E7:03
/ip dhcp-server lease print show-ids detail where mac-address=52:54:00:D4:BD:37
```

| Resource | RouterOS ID | Imported | Zero-diff plan |
| --- | --- | --- | --- |
| `routeros_ip_dhcp_server_lease.nmac` | `*1AB0` (verified `2026-07-11`) | no | no |
| `routeros_ip_dhcp_server_lease.home_assistant` | `*1AB7` (verified `2026-07-11`) | no | no |

For each row, substitute the reviewed ID and run:

```sh
tofu -chdir=opentofu/routeros import routeros_ip_dhcp_server_lease.nmac '*ID'
tofu -chdir=opentofu/routeros plan -detailed-exitcode
make backup-opentofu STACK=routeros

tofu -chdir=opentofu/routeros import routeros_ip_dhcp_server_lease.home_assistant '*ID'
tofu -chdir=opentofu/routeros plan -detailed-exitcode
make backup-opentofu STACK=routeros
```

Exit `0` is required. Exit `2` means the declaration must be corrected from observed state before continuing; do not apply it.
