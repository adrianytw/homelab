# Recovery command log

No Home Assistant shutdown or restore command has run. The `br0` migration is
complete, and the HA-created backup bundle is freshness-checked without opening
its recovery passphrase.

The isolated HA restore and privileged `/srv/data` procedures remain attended
review gates.

## 2026-07-12 reliability preparation

Installed user-local age `1.1.1`, checksum-verified SOPS `3.13.2`, and kubectl
`1.36.2`. Repository checks, backup failure/recovery fixtures, Kustomize render,
Ansible syntax, secret scan, and `git diff --check` passed. At that point, live
server dry-run, alert, backup, restore, and reboot proof still awaited the
maintenance-wrapper install; the following acceptance records close those
unattended lanes.

## 2026-07-13 reliability acceptance

- The guarded node-exporter selector failure fired `MonitoringTargetDown`; fresh
  firing and resolved messages reached the private `homelab-alerts` topic.
- Flux repaired the selector and Prometheus recovered its `alertmanager`, `nmac`,
  and `prometheus` targets.
- Six backup sets were created at timestamps `062159`, `062300`, `062421`,
  `062531`, `062651`, and `062811` UTC. All directories are `0700`; archives and
  checksums are `0600`. Checksums, encrypted tar listings, and SQLite checks pass.
- The Uptime Kuma archive restored to scratch with `quick_check=ok` and the
  then-current seven monitors. Current validation requires all eleven desired
  monitors while allowing extra manual monitors.
- The guarded reboot produced observed SSH loss and recovery. sshd, firewalld,
  k3s, cert-manager, Flux, all six applications, Grafana, three Prometheus
  targets, Alertmanager discovery, and Home Assistant recovered.
- RouterOS, AdGuard, DNS, DHCP, firewall configuration, WireGuard, certificates,
  ingress, and public exposure were not changed.

## 2026-07-13 production operations acceptance

- Configuration revision `48b4b11` reached `Ready=True` in all six application
  Flux Kustomizations; all six Deployments were `1/1` available. GitHub and the
  bare off-host mirror held the same revision.
- All ten HTTP destinations returned `200` after configured redirects. Glance
  rendered Operations, Infrastructure, and Source/Test, all nine service names,
  and nine healthy status icons. The Uptime Kuma snapshot
  `20260713T103113Z` contained exactly eleven desired active monitors and a
  healthy latest heartbeat for each, including the separate AdGuard DNS check.
- Prometheus reported 10/10 active targets up and 13/13 alert rules healthy.
  Flux controllers, cert-manager, Traefik, `nmac`, Alertmanager, Prometheus, and
  RouterOS resource telemetry were present. Grafana served the provisioned,
  non-editable `nmac-overview`, `platform-overview`, and `routeros-overview`
  dashboards.
- Healthchecks snapshot `20260713T102817Z` contained only the `Homelab` project,
  one active ntfy webhook, one active superuser, and four `up` checks: application
  backups, AdGuard backup, RouterOS backup, and HA backup freshness. A forced
  backup failure and recovery had already produced both DOWN and recovered ntfy
  notifications through the topic-limited publisher.
- The cron service is active and enabled. Its managed block has exactly four
  jobs: daily application backup at 03:15, daily AdGuard backup at 03:45, weekly
  RouterOS backup Sunday at 04:15, and daily HA freshness validation at 05:00.
- RouterOS pack `20260713T102327Z` passed outer and inner checksums. Its random
  48-character binary password exists only in process memory and a nested
  age-encrypted sidecar; no plaintext password, local stage, or router temporary
  file remained. The last proven AdGuard configuration pack was
  `20260713T094811Z`; HA freshness validated pack `20260712T015903Z`.
- No ingress, DNS, DHCP, firewall, WireGuard, RouterOS service, certificate, or
  public-exposure change was made. `ha.nairdev.com` remains unresolved by design;
  Home Assistant is monitored directly at `192.168.88.84:8123`.

## 2026-07-11 bridge and firewall evidence

```sh
ssh -o BatchMode=yes -o ConnectTimeout=8 nmac 'timeout 6 nmcli -f connection.id,connection.uuid,connection.type,connection.interface-name,802-3-ethernet.cloned-mac-address,ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns,ipv4.never-default,ipv6.method connection show "Wired connection 2"; timeout 6 nmcli -f GENERAL.CONNECTION,GENERAL.DEVICE,GENERAL.TYPE,GENERAL.HWADDR,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show enu1u1c2; ip -brief link; ip route show'
ssh -o BatchMode=yes -o ConnectTimeout=8 nmac 'timeout 6 firewall-cmd --state 2>&1 || true; systemctl is-active firewalld; systemctl is-enabled firewalld; timeout 6 virsh domiflist haos --inactive'
```

Outcome: the active DHCP profile UUID, host MAC, route, DNS, and macvtap presence were confirmed. Firewalld is enabled/active, but rule inventory and inactive libvirt XML are privilege-gated. The HA bridge and k3s/firewall execution packets were prepared; no live change ran.
