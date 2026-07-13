# Monitoring Recovery

## Purpose

Recover and validate Uptime Kuma, Prometheus, Alertmanager, the ntfy bridge,
node-exporter, and Grafana after
the underlying host, data, k3s, age identity, and Flux are healthy.

## Prerequisites

- Follow the recovery order in `README.md`.
- Restore the SOPS age identity outside Git before Flux decrypts app secrets.
- Verify the encrypted Uptime Kuma archive checksum before decrypting it.
- Stop Uptime Kuma before copying or restoring its SQLite PVC.
- Subscribe an ntfy client to the private `homelab-alerts` topic on
  `https://notify.nairdev.com`; use the existing ntfy administrator login.

## Validation

- Every Flux Kustomization reports `Ready=True` at the same Git revision.
- Prometheus reports `up=1` for `prometheus` and `nmac`.
- Prometheus loads `MonitoringTargetDown`, `NmacDiskSpaceLow`, and
  `NmacMemoryLow` with rule health `ok`.
- Prometheus discovers `alertmanager.core.svc.cluster.local:9093`; Alertmanager
  reports its configuration healthy and the bridge `/health` endpoint is ready.
- A controlled `MonitoringTargetDown` test produces one firing notification and
  one resolved notification in ntfy. Resume Flux and confirm selector repair.
- Grafana serves the provisioned `nmac overview` dashboard.
- Uptime Kuma shows successful heartbeats for the six core web services, Home
  Assistant, and AdGuard DNS through the client endpoint at `192.168.88.1`.
- Delete the node-exporter pod once and confirm its DaemonSet and scrape recover.

## Rollback

Suspend the affected Flux Kustomization, apply the last known-good manifest,
and restore the most recent verified encrypted application archive. Keep the
failed data and archive until validation finishes; never overwrite the only
copy. Resume Flux only after the manual workload is healthy.

If alert delivery alone fails, inspect Prometheus Alertmanager discovery,
Alertmanager status, and bridge logs in that order. Do not make either service
public.
