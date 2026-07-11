# RouterOS imports

Record the RouterOS ID and successful zero-diff plan for each resource. Never batch these imports.

```routeros
:put [/ip/dhcp-server/lease get [find where mac-address=F8:E4:3B:54:E7:03] value-name=.id]
:put [/ip/dhcp-server/lease get [find where mac-address=52:54:00:D4:BD:37] value-name=.id]
```

| Resource | RouterOS ID | Imported | Zero-diff plan |
| --- | --- | --- | --- |
| `routeros_ip_dhcp_server_lease.nmac` | pending | no | no |
| `routeros_ip_dhcp_server_lease.home_assistant` | pending | no | no |

For each row, substitute the reviewed ID and run:

```sh
tofu import routeros_ip_dhcp_server_lease.nmac '*ID'
tofu plan -detailed-exitcode

tofu import routeros_ip_dhcp_server_lease.home_assistant '*ID'
tofu plan -detailed-exitcode
```

Exit `0` is required. Exit `2` means the declaration must be corrected from observed state before continuing; do not apply it.
