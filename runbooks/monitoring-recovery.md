# Monitoring Recovery

## Purpose

Recover and validate Uptime Kuma, Prometheus, node-exporter, and Grafana after
the underlying host, data, k3s, age identity, and Flux are healthy.

## Prerequisites

- Follow the recovery order in `README.md`.
- Restore the SOPS age identity outside Git before Flux decrypts app secrets.
- Verify the encrypted Uptime Kuma archive checksum before decrypting it.
- Stop Uptime Kuma before copying or restoring its SQLite PVC.

## Validation

- Every Flux Kustomization reports `Ready=True` at the same Git revision.
- Prometheus reports `up=1` for `prometheus` and `nmac`.
- Prometheus loads `MonitoringTargetDown`, `NmacDiskSpaceLow`, and
  `NmacMemoryLow` with rule health `ok`.
- Grafana serves the provisioned `nmac overview` dashboard.
- Uptime Kuma shows successful heartbeats for the six core web services and
  Home Assistant.
- Delete the node-exporter pod once and confirm its DaemonSet and scrape recover.

## Rollback

Suspend the affected Flux Kustomization, apply the last known-good manifest,
and restore the most recent verified encrypted application archive. Keep the
failed data and archive until validation finishes; never overwrite the only
copy. Resume Flux only after the manual workload is healthy.
