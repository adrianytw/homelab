# Recovery command log

No Home Assistant shutdown, backup, restore, or network migration command has run. Read-only VM facts were collected over SSH on `2026-07-11`.

The HA and `/srv/data` procedures were expanded from placeholders, but remain review-gated and unexecuted.

## 2026-07-12 reliability preparation

Installed user-local age `1.1.1`, checksum-verified SOPS `3.13.2`, and kubectl
`1.36.2`. Repository checks, backup failure/recovery fixtures, Kustomize render,
Ansible syntax, secret scan, and `git diff --check` pass. Live server dry-run,
alert, backup, restore, and reboot proof remain blocked only on the attended
maintenance-wrapper install.

## 2026-07-13 reliability acceptance

- The guarded node-exporter selector failure fired `MonitoringTargetDown`; fresh
  firing and resolved messages reached the private `homelab-alerts` topic.
- Flux repaired the selector and Prometheus recovered its `alertmanager`, `nmac`,
  and `prometheus` targets.
- Six backup sets were created at timestamps `062159`, `062300`, `062421`,
  `062531`, `062651`, and `062811` UTC. All directories are `0700`; archives and
  checksums are `0600`. Checksums, encrypted tar listings, and SQLite checks pass.
- The Uptime Kuma archive restored to scratch with `quick_check=ok` and exactly
  seven monitors.
- The guarded reboot produced observed SSH loss and recovery. sshd, firewalld,
  k3s, cert-manager, Flux, all six applications, Grafana, three Prometheus
  targets, Alertmanager discovery, and Home Assistant recovered.
- RouterOS, AdGuard, DNS, DHCP, firewall configuration, WireGuard, certificates,
  ingress, and public exposure were not changed.

## 2026-07-11 bridge and firewall evidence

```sh
ssh -o BatchMode=yes -o ConnectTimeout=8 nmac 'timeout 6 nmcli -f connection.id,connection.uuid,connection.type,connection.interface-name,802-3-ethernet.cloned-mac-address,ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns,ipv4.never-default,ipv6.method connection show "Wired connection 2"; timeout 6 nmcli -f GENERAL.CONNECTION,GENERAL.DEVICE,GENERAL.TYPE,GENERAL.HWADDR,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show enu1u1c2; ip -brief link; ip route show'
ssh -o BatchMode=yes -o ConnectTimeout=8 nmac 'timeout 6 firewall-cmd --state 2>&1 || true; systemctl is-active firewalld; systemctl is-enabled firewalld; timeout 6 virsh domiflist haos --inactive'
```

Outcome: the active DHCP profile UUID, host MAC, route, DNS, and macvtap presence were confirmed. Firewalld is enabled/active, but rule inventory and inactive libvirt XML are privilege-gated. The HA bridge and k3s/firewall execution packets were prepared; no live change ran.
